---
layout: post
title: Including and extending modules in Ruby
tags:
- en_US
- object orientation
- rails
- ruby
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  delicious: s:79:"a:3:{s:5:"count";s:2:"17";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1277927880";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1277927890";}";
  dsq_thread_id: '217521026'
  _su_keywords: ''
  _su_description: ''
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
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:9;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}}
  _relation_threshold: '2'
---
[caption id="attachment_149" align="alignleft" width="122" caption="The Ruby Programming Language"]<a href="http://www.amazon.com/gp/product/0596516177?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=0596516177"><img src="http://techbot.me/wp-content/uploads/2011/01/ruby.jpg" alt="The Ruby Programming Language" title="The Ruby Programming Language" width="122" height="160" class="size-full wp-image-149" /></a>[/caption]One of the coolest features in Ruby is the existence of modules and the possibility of including their implementation in any object. This simple behavior is the source of things like the <a href="http://www.ruby-doc.org/core/classes/Enumerable.html">Enumerable</a> module, that gives you a bunch of methods to work with a collection of objects and just expects that the class that included it to define an “each” method. You write a class, define an “each” method, include Enumerable and your're done, all Enumerable methods are available for you.

Another example is the <a href="http://www.ruby-doc.org/core/classes/Comparable.html">Comparable</a> module, when you include the Comparable module in your class, you must define the  operator (the <a href="http://en.wikipedia.org/wiki/UFO">UFO</a> operator), the Comparable module will give you the implementation the following operators/methods:

<pre class="brush:ruby">&lt; , &lt;= , &gt; , &gt;= , ==, between?</pre>

This is usually why we call them mixins, because they are “mixing in” their behaviors (their methods/messages) into our objects. The idea of mixins serve a purpose similar to that of the multiple inheritance, that is to inherit an implementation from “something” without having to be a direct child of that “something”, in multiple inheritance you would be able to inherit from as many classes as you wanted to. In Ruby we don't have multiple inheritance, but we can include as many modules as we want, so they give us the same feature, without all the hassle that multiple inheritance usually brings to a language.

The method resolution mechanism is pretty simple, first, if a method in a module that is being included is already defined in the class that is including it, the method of the class has precedence (which means that the method on the module will be ignored). If two modules define a method with the same name, the method on the last module included will be the one available at the class that has included both modules (remember that in Ruby there is no method overloading mechanism). Here's an example of how it works:

<pre class="brush:ruby">module SimpleModule

  def a_method
    puts 'a_method at module'
  end

  def another_method( parameter )
    puts &quot;Calling another method with parameter -&gt; #{parameter}&quot;
  end

end

module AnotherModule

  def another_method
    puts 'Calling another method without a parameter'
  end

end

class SimpleClass

  include SimpleModule
  include AnotherModule

  def a_method( param )
    puts &quot;a_method at class -&gt; #{param}&quot;
  end

end

instance = SimpleClass.new

#calling the method defined on the class
instance.a_method 'parameter'

#calling method on the AnotherModule
instance.another_method

#this line will throw a 'wrong number of arguments' error
instance.a_method</pre>

An ugly example for an ugly practice, don't rely on these things when you're writing your own modules, strive to create unique modules that aren't going to have method names clashing when they are included in other classes. If you have to rely on these rules to write and use your modules, maybe there is a problem in your code or in what you're trying to do.

<h3>Extending methods</h3>

As the title of this post says, you can include and also extend modules, but what does it means to extend a module?

When you extend a module, you are adding the methods of that specific module into the object instance you call “extend”. So, the methods of that module will only be available at that specific instance (and not all objects of that class), other objects of the same class will not have the methods of the module available. With this, you can add specific behaviors to just one object of your system, without changing the other ones. Here's an example:

<pre class="brush:ruby">module InstanceMethods

  def simple_method
    puts &quot;im a method that belongs to an instance&quot;
  end

end

class SimpleObject
end

object = SimpleObject.new
object.extend InstanceMethods
object.simple_method

another_object = SimpleObject.new

#the following line will throw an error, as this instance doesn't extends the module
another_object.simple_method</pre>

This might look like a weird feature, how many times have you wanted to introduce a method into a single object?

Not that many, probably, unless this instance is in fact an instance of the Class class (that contains the class methods of your object), and this is where extending modules get interesting and this is how many of the Rails plugins are written, let's see how we can use this to write our own acts_as_votable plugin.

<h3>Rails, extending and including modules</h3>

First thing to do is create your Rails project:

<pre class="brush:shell">rails --database=mysql include_extend_modules</pre>

With the project created, we have to create our plugin (enter in your Rails project folder):

<pre class="brush:shell">script/generate plugin acts_as_votable</pre>

This will create a folder called acts_as_votable at the vendor/plugins folder and the plugin skeleton code. The first thing to do is to create our Vote model. It's a dead simple model, with a polymorphic relationship with a “votable” and a boolean column called “up”, representing if this vote is “up” or “down”. The vote.rb file should live at the vendor/plugins/acts_as_votable/lib folder. Here's the model code:

<pre class="brush:ruby">#vendor/plugins/acts_as_votable/lib/vote.rb

class Vote &lt; ActiveRecord::Base
  belongs_to :votable, :polymorphic =&amp;gt; true
  validates_presence_of :votable
end</pre>

Now we have to create a migration to create the votes table at the database:

<pre class="brush:shell">script/generate migration create_votes</pre>

And there is the migration code:

<pre class="brush:ruby">class CreateVotes &lt; ActiveRecord::Migration
  def self.up

    create_table :votes do |t|
      t.integer :votable_id, :null =&gt; false
      t.string :votable_type, :limit =&gt; 15, :null =&gt; false
      t.boolean :up, :default =&gt; false, :null =&gt; false
      t.timestamps
    end

    add_index :votes, [ :votable_id, :votable_type ]

  end

  def self.down

    drop_table :votes

  end
end</pre>

After creating the Vote model and it's migration, we'll head to that acts_as_votable.rb file in our plugin folder, it's where the code that ties the Vote model with the application will live, here's the code that will be in there:

<pre class="brush:ruby">#vendor/plugins/acts_as_votable/lib/acts_as_votable.rb

module ActsAsVotable

  module ClassMethods

    def acts_as_votable
      has_many :votes, :as =&gt; :votable, :dependent =&gt; :delete_all
      include InstanceMethods
    end

  end

  module InstanceMethods

    def cast_vote( vote )
      Vote.create( :votable =&gt; self, :up =&gt; vote == :up )
    end

  end

end</pre>

We have created a module called ActsAsVotable to serve as our namespace and in it we have two modules ClassMethods and InstanceMethods. The ClassMethods module defines the methods that we want to introduce at the ActiveRecord::Base class, so that we can just call “acts_as_votable” in any model that inherits from ActiveRecord::Base (just like any other ActiveRecord plugin) and the InstanceMethods module contains the methods that we want an instance that is “votable” to have.

So, if I say that a NewsArticle class is votable, its instances will have the cast_vote method, as the module InstanceMethods was included when they called acts_as_votable. But before creating the NewsArticle model, we have to do some changes in our init.rb file for the acts_as_votable plugin, here's how it should look like:

<pre class="brush:ruby">#vendor/plugins/acts_as_votable/init.rb

require 'vote'
require 'acts_as_votable'

ActiveRecord::Base.extend ActsAsVotable::ClassMethods</pre>

This is where we make the acts_as_votable method available to all classes that inherit from ActiveRecord::Base and this is one of the most common uses of “extending” modules you will see.

Now that we have the code hooked to ActiveRecord, let's create a simple model to try some tests, create our NewsArticle model:

<pre class="brush:shell">script/generate model NewsArticle title:string article:text</pre>

Now, at the news_article.rb file:

<pre class="brush:ruby">#app/models/news_article.rb

class NewsArticle &lt; ActiveRecord::Base

  acts_as_votable
  validates_presence_of :title, :article

end</pre>

We just call the acts_as_votable class method, that is available as we “exetended” the ActsAsVotable::ClassMethods module into the ActiveRecord::Base class, the superclass of our NewsArticle class. Here's an example of you could do with our models:

<pre class="brush:ruby">article = NewsArticle.create(:title =&gt; 'sample', :article =&gt; 'sample')

#calling the cast_vote method from the ActsAsVotable::InstanceMethods module
article.cast_vote :up
article.cast_vote :down

#acessing the votes association defined when you called the acts_as_votable method
article.votes</pre>

And that's it, you now know how and when to include or extend modules and even how to build a simple acts_as plugin for your models.

PS: You can get the full code for this example <a href='http://blog.codevader.com/wp-content/including_extending_modules.zip'>here</a>. This post was originally published at the <a href="http://blog.codevader.com/2008/09/27/including-and-extending-modules-in-ruby/">CodeVader blog</a>.
