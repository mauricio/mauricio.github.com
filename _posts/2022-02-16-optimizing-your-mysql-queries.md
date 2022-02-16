---
layout: post
title: Optimizing your MySQL queries
keywords: mysql, sql, optimization
tags:
- useful
---

Odds are, if you're doing any commercial programming, you've had to interact with a SQL database. They're a staple in programming due to how easy it is to store and retrieve data on them and the many free and open-source options available. Still, people have trouble figuring out how to optimize their queries correctly, so let's fix that.

While this text is focused on MySQL specifically, most of the discussion is also true for other databases. So, even if you don't use MySQL, you should learn something new that is going to be helpful on the SQL database you're using right now.

The database we'll use here is the [employees db](https://github.com/datacharmer/test_db) from MySQL itself. [This repo has a docker-compose setup](https://github.com/mauricio/mysql-example) on how to start and run the database so you can run the commands along.

## *EXPLAIN* to me

The first thing you have to learn to optimize queries in relational databases is to use the `EXPLAIN` command. `EXPLAIN` runs the query you've created through the database engine to check what it thinks it's going to take to run the command. It won't run the command, but it checks how many rows it believes it will need to access to satisfy the query.

So given the following table:

```sql
CREATE TABLE employees (
    emp_no      INT             NOT NULL,
    birth_date  DATE            NOT NULL,
    first_name  VARCHAR(14)     NOT NULL,
    last_name   VARCHAR(16)     NOT NULL,
    gender      ENUM ('M','F')  NOT NULL,    
    hire_date   DATE            NOT NULL,
    PRIMARY KEY (emp_no)
);
```

And a query that finds all the employees named `Joe`:

```sql
SELECT * FROM employees WHERE first_name = "Joe";
```

You running a query with `EXPLAIN` before it all, so an `EXPLAIN` on the previous query would be:

```sql
EXPLAIN SELECT * FROM employees WHERE first_name = "Joe"\G 
```

The `\G` here is specific to MySQL to say you want the data printed in rows. Here's what it prints:

```sql
mysql> EXPLAIN SELECT * FROM employees WHERE first_name = "Joe"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: employees
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 299645
     filtered: 10.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

So when we ask the database what it thinks about this query, its response is a bit harsh. It says it has to look for 299645 rows (this table has 300024 entries, so it's almost every single row) to find out there are no employees named `Joe`. There are no keys to be used (keys here would be database indexes), and we're using a `WHERE` clause to filter the results.

So, we know we have to find users given the first name, and the `EXPLAIN` response shows there are no indexes on this specific column, let's add one:

```sql
CREATE INDEX employees_first_name_idx ON employees (first_name);
```

Now running `EXPLAIN` again:

```sql
mysql> EXPLAIN SELECT * FROM employees WHERE first_name = "Joe"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: employees
   partitions: NULL
         type: ref
possible_keys: employees_first_name_idx
          key: employees_first_name_idx
      key_len: 58
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

A single row checked!

How did this happen?

When you ask for the database to create an index on a column, it creates an optimized structure that allows you to find all rows associated with a specific value quickly. Think about it as if it maps a value ("Joe") to all rows that have that value on the column you created the index.

Indexes are the magical solution. We should create indexes for every column in the table, and we should be good, right?

## "You should have an index for all columns you use for querying a table"

This is a pretty common misconception of how indexes work in relational databases. If you have an index for every column, every query is automatically optimized as the database can use all these indexes to find the rows, but this is not true.

MySQL can, in some cases, use more than one index when querying data. If we create separate indexes on `first_name` and `last_name` and try to find a specific user with values for both, we get this:

```sql
mysql> EXPLAIN SELECT * FROM employees WHERE last_name = 'Halloran' AND first_name = 'Aleksander'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: employees
   partitions: NULL
         type: index_merge
possible_keys: employees_first_name_idx,employees_last_name_idx
          key: employees_last_name_idx,employees_first_name_idx
      key_len: 66,58
          ref: NULL
         rows: 1
     filtered: 100.00
        Extra: Using intersect(employees_last_name_idx,employees_first_name_idx); Using where
 ```

So, we're still doing good, only one row checked, but the extra field has an interesting reference, `intersect(employees_last_name_idx,employees_first_name_idx)`. MySQL sees two indexes here and decides to use them both for the query. It's still better than not having an index, but we're going through two separate data structures to find the value instead of a single one.

If we now get an index on both `last_name` and `first_name`, this is the output:

```sql 
mysql> EXPLAIN SELECT * FROM employees WHERE last_name = 'Halloran' AND first_name = 'Aleksander'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: employees
   partitions: NULL
         type: ref
possible_keys: employees_first_name_idx,employees_last_name_idx,employees_last_first_name_idx
          key: employees_last_first_name_idx
      key_len: 124
          ref: const,const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

The server digs into a single index to find the row that matches the expected value instead of two. Having multiple rows in an index also helps with covering indexes, a feature we'll discuss later.

## Picking index columns

Picking indexes is about how you query the table and what fields are part of the queries. When looking for employees, we want to find them by first and last name, so we have an index on both of them. When creating an index for multiple columns, the *order* of the columns matters.

Given we have an employee called `Georgi Facello`, our index would have it referenced under the entry `Facello-Georgi` (the index is `last_name, first_name`), so it only works for queries where you are looking for  `last_name` and `first_name` or `last_name` alone. A query that only looks for `first_name` can't use this index as the index matches left-to-right. For that, you'd need an index that starts with `first_name`.

It's also not valid for a query where you need to find someone given a `last_name` *or* a `first_name`, as you'd need both columns to be the leftmost columns in the indexes used, this would be a case where having separate indexes on the columns would be helpful. MySQL would run a union on both indexes to perform the query.

Now, if you're querying all or most columns in the index, what order should they have?

The columns with the biggest variety in values should come first. You can quickly calculate an average of how common values are in a column with a query like the following:

```sql
mysql> SELECT COUNT(DISTINCT emp_no)/COUNT(*) FROM employees;
+---------------------------------+
| COUNT(DISTINCT emp_no)/COUNT(*) |
+---------------------------------+
|             1.0000              |
+---------------------------------+
```

The primary key is the perfect example. Every row has a unique value, so we get *1*. We now want the columns we'll use in the index to be as close to *1* as we can, let's look at `first_name`:

```sql
mysql> SELECT COUNT(DISTINCT first_name)/COUNT(*) FROM employees;
+-------------------------------------+
| COUNT(DISTINCT first_name)/COUNT(*) |
+-------------------------------------+
|               0.0042 |
+-------------------------------------+
```

Then look at `last_name`:

```sql 
mysql> SELECT COUNT(DISTINCT last_name)/COUNT(*) FROM employees;
+------------------------------------+
| COUNT(DISTINCT last_name)/COUNT(*) |
+------------------------------------+
|               0.0055               |
+------------------------------------+
```

So `last_name` gives us better filtering than `first_name`, making it the best column on the index's left side. Still, this is an average, and as you might have found out the hard way in other places, averages are good at hiding outliers. One here would impact query performance directly so we also want to check if there are visible outliers on these columns:

```sql
mysql> SELECT last_name, COUNT(*) AS total FROM employees GROUP BY last_name ORDER BY total DESC LIMIT 10;
+-----------+-------+
| last_name | total |
+-----------+-------+
| Baba      |  226  |
| Gelosh    |  223  |
| Coorg     |  223  |
| Sudbeck   |  222  |
| Farris    |  222  |
| Adachi    |  221  |
| Osgood    |  220  |
| Mandell   |  218  |
| Neiman    |  218  |
| Masada    |  218  |
+-----------+-------+
```

So no outliers here. Values seem to be pretty close to each other. Let's look at `first_name`:

```sql 
mysql> SELECT first_name, COUNT(*) AS total FROM employees GROUP BY first_name ORDER BY total DESC LIMIT 10;
+-------------+-------+
| first_name | total |
+-------------+-------+
| Shahab      |  295 |
| Tetsushi    |  291 |
| Elgin       |  279 |
| Anyuan      |  278 |
| Huican      |  276 |
| Make        |  275 |
| Sreekrishna |  272 |
| Panayotis   |  272 |
| Hatem       |  271 |
| Giri        |  270 |
+-------------+-------+
```

Not bad either. Values aren't that far from each other. The order we decided on for the index is a pretty good one.

Now, something else you need to account for when creating indexes is how you will sort the results?

Just like the database uses the index to find rows quickly, it can also sort the results if you're sorting on the same columns *in the index order*. For our `last_name, first_name` index it would mean to `ORDER BY last_name` or `ORDER BY last_name, first_name`. If multiple columns are sorted, they all have to be in the same *direction*, so either all `ASC` or all `DESC`. If they're not all in the same order the database can't use the index itself to sort the results and would have to resort to temporary tables to load the results and sort them.

## Covering indexes

And another important reason to have indexes that hold multiple columns is the covering indexes feature that MySQL provides. When your query only loads the primary key and columns in the index, the database doesn't even have to look at the tables to read the results. It reads everything from the index alone. Here's what it looks like:

```sql
mysql> explain select emp_no, last_name, first_name from employees where last_name = "Baba"\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: employees
   partitions: NULL
         type: ref
possible_keys: employees_last_name_idx,employees_last_first_name_idx
          key: employees_last_first_name_idx
      key_len: 66
          ref: const
         rows: 226
     filtered: 100.00
        Extra: Using index
```

The hint here is `Extra: Using index`, which means all the data is read from the index alone. As the index already contains all the information we need (all indexes include the primary key for the table), the database loads everything from it and returns, not even reaching out to the table. This is the best-case scenario for queries, especially if your index fits into memory.

## Creating multiple indexes

Creating indexes isn't free. While they make it faster for us to *find* data, they also slow down any changes to the table as writing to columns with indexes will cause these indexes to be updated. So you have to strike a balance between making as many queries as possible fast but also allowing for fast `INSERT/UPDATE/DELETE` commands.

## Summary

So, when optimizing, remember to:
* Use `EXPLAIN` to find out how the database thinks your query will perform - [check the command docs here](https://dev.mysql.com/doc/refman/8.0/en/explain-output.html);
* Create indexes that cover the filtering and ordering you want to perform on your queries;
* Evaluate the best order for the columns when creating indexes;
* Try to load as much information from covering indexes as possible;

One of the best references to optimizing MySQL databases is the [High Performance MySQL](https://learning.oreilly.com/library/view/high-performance-mysql/9781492080503/) that is in its 4th edition and covers from database internals to how to design your database schema to make the most of MySQL. If you're running apps on MySQL, you should read it. If you're not using MySQL, it's very likely there is a book just like this one for it as well, and you should invest some time in reading it.
