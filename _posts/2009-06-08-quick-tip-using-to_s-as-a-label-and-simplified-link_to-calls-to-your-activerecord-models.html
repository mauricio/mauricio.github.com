---
layout: post
title: Quick Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
  models
tags:
- en_US
- rails
- ruby
- ruby on rails
- tips
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  _wp_old_slug: quick-tip-%e2%80%93-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1295161470";}";
  delicious: s:78:"a:3:{s:5:"count";s:1:"0";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1280621448";}";
  _su_keywords: ''
  dsq_thread_id: '218401800'
  _su_description: ''
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:3;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:6;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:7;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
---
One of the things you’ll find in every rails application is links like this one:

<pre class="brush:plain">&lt; %= link_to user.login, user %&gt;</pre>

Or maybe like this one:

<pre class="brush:plain">&lt; %= link_to user.login, user_path( user ) %&gt;</pre>

Or maybe something ugly like this one:

<pre class="brush:plain">&lt; %= link_to user.to_label, user_path( user ) %&gt;</pre>

How about throwing all of them and just doing it like this:

<pre class="brush:plain">&lt; %= link_to user %&gt;</pre>

Cool, isn’t it?

Now “how can I do that” you ask, it’s dead simple. First, remember that every object responds to a method called “to_s” and this “to_s” method is defined as “a method that returns a string representation of your object” in most programming languages, including Ruby.

A string representation of your object is something human readable that would tell someone else what this object represents. “to_s” isn’t meant to be a debug like method, we already have “inspect” to do that, so why not put it to work and simplify our links?

At every ActiveRecord model in your application you’ll define a to_s method that returns one (or maybe more, if needed) attributes of your object as a string (if they’re not strings, turn them into strings and return). Let’s see how your user would look like:

<pre class="brush:ruby">class User &lt; ActiveRecord::Base
  validates_presence_of :login
  validates_uniqueness_of :login
  def to_s
    self.login
  end
end</pre>

I decided that the "login" method is the one that best represents the User object and it's also the one I want to use then someone else seers users on the website. They won't see their real names by default, but their logins.

Why is it better to do this with the "to_s" method instead of adding a “to_label” method to all objects? ‘Cos many helpers will already call the to_s method by default on your object (as we'll see with the link_to helper), so you just get full compatibility for free. Check out our new link_to implementation:

<pre class="brush:ruby">module ApplicationHelper
  #sample link_to override that will generate urls for active_record objects by default
  #if the first parameter is an active_record object and you just want a link to it,
  # you can call it just like this:
  # &lt;%= link_to user %&gt;
  # the helper will take care of generating the correct url
  def link_to( *args )
    options = args.extract_options!
    if args.size == 1 &amp;&amp; args.first.is_a?( ActiveRecord::Base )
      super( *([ args.first, args.first ] + [ options ]) )
    else
      super( *( args + [ options ] ) )
    end
  end
end</pre>

If there’s only one object (besides the options hash) and it is an ActiveRecord::Base instance, just use the object itself as the url parameter (the real link_to helper will call polymorphic_url on it automatically) and also use the object as the link_to label (the first parameter), this will call the to_s method on our user and the link will use it as the label.

What do you get with this?

A seamless and clear way of defining labels for your models (the “to_s” method is part of the core of the language anyway) and also a simpler way of generating links for your objects. Common methods for object labels are very important because you can never be sure if the property you’re using today as a label will be used forever. Using the “to_s” method as the default “label method” will allow you to change the label property at any time with almost no change to other parts of the code.
