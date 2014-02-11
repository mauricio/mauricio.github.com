---
layout: post
title: SQL functions in WHERE clauses are evil
tags:
- useful
---
Once we get up an running with the basic SQL syntax, doing inserts, updates, deletes and simple selects we start to learn about the SQL functions, the default ones like LOWER, COUNT, AVG and then the functions that are specific for the database you're using. We learn them and start to feel that your fingers are itching to try them, to use them in the real world. Why would you learn them if you can't use them anyway?

Well, I can't tell you that you should never use them, but listen to my advice, do not ever use these SQL functions in WHERE clauses to filter data. They're evil and they'll try to kill your database and prevent you from working by having to discover crazy performance bottlenecks and slow queries that don't look slow at all. At least until you run an “EXPLAIN” on them.

Let's start with a simple example, we want to know, from our USERS table, which ones where born today so we can send them a beautiful and unpersonal e-mail to remember that they are getting older today. In your USERS table there is a column called “date_of_birth” which is a DATE and obviously it stores the date that the user said he was born at, so we know the day, month and year, we already have all information that we need, now it's time to write the SQL code to find them.

In our first attempt, we write the following simple SQL:

<pre class="brush:sql">SELECT * FROM users u where DAYOFMONTH(u.date_of_birth) = 12 AND MONTH(u.date_of_birth) = 1</pre>

Pretty simple and does the job perfectly, running it in your test database returns the correct users and it's definitely fast. Now we get to try it in our production database so you can figure out which users are going to receive the e-mail. We're running a big website, with a gazillion of users, so there should be some of them that are getting older today, we type in the query at your production database console and...

Wait.

Waiting.

Still waiting and looking at that blank console screen.

Well, you should find yourself something else to read, it's going to take a while. After a long time waiting you get a list with 10 users with birthdays today. WTF? Why so long just to find 10 users?

A light shines in our heads and we remember that there is no index at the "date_of_birth" column, we never thought about using it in queries so we, as good database guys, did not create an index when it wasn't needed. But now it is and you just type in the command to create the index for the "date_of_birth" column.

After waiting a little bit to have the index created, we type again our beautiful query and we wait again. This time it seems that's it's taking even longer to finish. This is clearly wrong, we have created an index at that database field and queries against that field should use that index. Now we have to bring the most important tool of anyone that has ever used a database, the “explain query” feature, which explains how a query is going to be executed by the database. At your database console, we type (this is for MySQL):

<pre class="brush:sql">explain select * from users u where DAYOFMONTH(u.date_of_birth) = 12 and MONTH(u.date_of_birth) = 1\G</pre>

And here's our output:

<pre class="brush:plain">*************************** 1. row ***************************

	id: 1
	select_type: SIMPLE
	table: users
	type: ALL
	possible_keys: NULL
	key: NULL
	key_len: NULL
	ref: NULL
	rows: 4558
	Extra: Using where
1 row in set (0.00 sec)</pre>

The most important lines are “possible_keys” and “key”, both of them are NULL, which means that our beautiful query isn't using any indexes. But another information is even more alarming, the database is looking at 4558 rows to retrieve my results (and this is exactly the count of rows available at the users table). The database is scanning the WHOLE users table to fetch some 8 rows. Can you feel it's pain?

We've created the index and we're trying to filter just on that column, why is it not being used?

Because we're using SQL functions, that's the reason. The DAYOFMONTH function is a transforming function, it takes an argument and generates a value based on that argument and our query is performing it's filtering based on this generated value. But here's the problem, the database optimizer doesn't know the generated value, it has no index for it nor a way to infer which value could be generated because it doesn't know what this SQL function does. The optimizer can't perform any optimizations at all.

When faced with such a complex query (from it's point of view) the optimizer has no option but let the query run against the whole database, selecting every row, applying the function to every column and then finally filtering the result. Every time you use a SQL function that is not native to your database, like DAYOFMONTH, LEFT, RIGHT or MONTH, you might be leading yourself to such a bad query and future bottleneck. When you're at your development database with a bunch of records, it might not yield any perceivable performance problems but once you reach the production environment with hundreds of rows, your problems will start to rise.

You should avoid filtering based on calculated or transformed data in you queries, as your database optimizer will not be able to give you the best “query plan”. If you're faced with such a problem, you should create a separate column at your table and generate the value beforehand. In our case, we would need to create two new columns, “day_of_birth” and “month_of_birth”, create an index for both of them and every time a row has it's “date_of_birth” updated, it should automatically update the “day_of_birth” and “month_of_birth” columns.

From now on, learn the mantra, SQL functions in where clauses are evil :)

<h2>Related Posts</h2>

<ul>
<li><a href="http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/">Handling database indexes for Rails polymorphic associations</a></li>
</ul>
