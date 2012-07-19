---
layout: post
title: Handling database indexes for Rails polymorphic associations
tags:
- database
- en_US
- mysql
- optimization
- rails
- ruby
- ruby on rails
status: publish
type: post
published: true
meta:
  _su_title: Handling database indexes for Rails polymorphic associations
  _su_keywords: ruby, rails, active record, polymorphic associations, mysql, index
  _edit_last: '1'
  delicious: s:79:"a:3:{s:5:"count";s:2:"13";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1277080524";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1281661903";}";
  dsq_thread_id: '217521029'
  _su_rich_snippet_type: none
  _su_description: Polymorphic associations are not going to use the same index you
    would setup for a basic association, learn how to correctly create indexes for
    them.
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:3;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:6;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:7;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:8;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:9;a:4:{s:2:"ID";s:2:"28";s:10:"post_title";s:39:"SQL
    functions in WHERE clauses are evil";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/12/sql-functions-in-where-clauses-are-evil/";}}
  _relation_threshold: '2'
---
[caption id="attachment_158" align="alignleft" width="122" caption="High Performance MySQL"]<a href="http://www.amazon.com/gp/product/0596101716?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=0596101716"><img src="http://techbot.me/wp-content/uploads/2011/01/mysql.jpg" alt="High Performance MySQL" title="High Performance MySQL" width="122" height="160" class="size-full wp-image-158" /></a>[/caption]One thing that is usually overlooked when defining tables and their associations in a Rails application are the indexes. Usually, this comes from the idea that “my ORM tool does the job” and in fact it might be true sometimes. One of the most successful ORM tools in the Java land, <a href="http://hibernate.org/">Hibernate</a>, generates a database with indexes for all foreign keys that you have, so Java programmers that use it don't really worry about these issues (at least not until their database is slowing down to death).

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
