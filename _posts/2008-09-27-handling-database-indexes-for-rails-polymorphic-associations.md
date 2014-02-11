---
layout: post
title: Handling database indexes for Rails polymorphic associations
tags:
- ruby
- rails
- useful
---

One thing that is usually overlooked when defining tables and their associations in a Rails application are the indexes. Usually, this comes from the idea that “my ORM tool does the job” and in fact it might be true sometimes. One of the most successful ORM tools in the Java land, <a href="http://hibernate.org/">Hibernate</a>, generates a database with indexes for all foreign keys that you have, so Java programmers that use it don't really worry about these issues (at least not until their database is slowing down to death).

ActiveRecord migrations, on the other side, don't really worry about these things ( unless you're using the cool <a href="http://www.redhillonrails.org/foreign_key_migrations.html">Foreign Key Migrations</a> plugin ), you must define the indexes that you need by yourself. Usually this is done by a simple call like this:

<pre class="brush:ruby">add_index :comments, :user_id</pre>

This will create an index for the column <strong>:user_id</strong> at the <strong>:comments</strong> table. For simple associations this is straightforward, but <em>ActiveRecord</em> offers goodies that are not so common in other tools and one of them is the “polymorphic associations”. With polymorphic associations you can define an association without defining the kind of the object you will be associated with, you just say that it's a polymorphic association and you're done. The code would look like this:

<pre class="brush:ruby">class Comment
    belongs_to :commentable, :polymorphic =&gt; true
    belongs_to :user
end</pre>

To make this work, at the database level you would need two columns at the <strong>:comments</strong> table, one called <strong>:commentable_id</strong>, that will hold the id of the object that owns the comment, and another called <strong>:commentable_type</strong>, that will hold the full class name of the object that owns the comment. So, if you're commenting in a Post object with an ID of 1, the commentable_id would be 1 and the commentable_type would be “<strong>Post</strong>”. At the Post model the association would look like this:

<pre class="brush:ruby">class Post
    has_many :comments, :as =&gt;  :commentable
    has_one :user
end</pre>

When you're using polymorphic associations, your queries for the object will usually contain the <strong>commentable_id</strong> and the <strong>commentable_type</strong> in the where clause, as you would be looking for comments for the <strong>commentable_id</strong> of 1 and <strong>commentable_type</strong> of “Post”, so it makes sense to create indexes for these columns. As you've already saw, you could do this with the following code:

<pre class="brush:ruby">add_index :comments, :commentable_id
add_index :comments, :commentable_type</pre>

And now you have two indexes, one for each column, your database searches should fly with this, shouldn't they?

Well, they will not. You're defining two different indexes, one for each column, but you almost never search for them in separate, you're always searching for the <strong>:commentable_id</strong> and also for the <strong>:commentable_type</strong>, so you should create an index for both columns and not for each one of them, the call should be something like this:

<pre class="brush:plain">add_index :comments, [ :commentable_type, :commentable_id]</pre>

This is going to generate an index with both columns and your queries for your polymorphic models will now really be faster than before.

Obviously, you can also create indexes for the <strong>:commentable_type</strong> and <strong>:commentable_id</strong> columns  if you search for them in separate, but having a lot of indexes in your table slows down update calls and might also create big tables in your filesystem. So, when defining polymorphic associations, remember to create an index for both columns and not just one for each of them. Also, if you know that the column will always have a value, make it not null, as searching on indexes of nullable columns in some databases (like MySQL) is slower then searching on not-null column indexes.

And before you go, when ActiveRecord creates a string column at the database level, you can define a :limit option that defines the size of the <strong>VARCHAR</strong> column at the database. If you don't give a limit, it's going to be set as a <strong>VARCHAR(255)</strong> and I really believe you will not have a model class with a name that has 255 characters, so, instead of creating a column with an unreasonable size (that is going to slow down queries and generate bigger indexes), give it a limit that's real. Our final table definition would look like this one:

<pre class="brush:plain">create_table :comments do |t|
  t.integer :user_id, :null =&gt; false #indexing nullable columns is slower, try to make all columns that are going to be in indexes not-null
  t.integer :commentable_id, :null =&gt; false
  t.string :commetable_type, :null =&gt; false, :limit =&gt; 20 #could be even less
  t.text :comment
end

add_index :comments, :user_id
add_index :comments, [:commentable_id, :commentable_type]</pre>

This post was originally published at the <a href="http://blog.codevader.com/2008/09/21/handling-database-indexes-for-rails-polymorphic-associations/">CodeVader weblog</a>.
