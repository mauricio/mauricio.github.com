---
layout: post
title: If you’re cleaning up your user’s input in your views you’re doing it wrong
tags:
- actionpack
- data sanitization
- en_US
- MVC
- rails
- ruby
- ruby on rails
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  delicious: s:78:"a:3:{s:5:"count";s:1:"3";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1281482611";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1295404657";}";
  dsq_thread_id: '217521094'
  _su_keywords: ''
  _su_description: ''
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:3;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:6;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:7;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
---
Have you ever found yourself using the "h" view helper all around your views in your applications? Have you ever thought that cleaning up user input in views is a tedious, error prone and cumbersome job?

You're not alone.

<!--more-->

Think with me, the user provides information <strong>once</strong> to your application, that information could be badly formatted, could be an XSS attack, but you store it as the user provided in your database. When you're about to show that information, something that could happen once or a hundred of times (you probably would like to have thousands of page views, wouldn’t you?) you finally clean it up, instead of cleaning it up just once when the user provided it.

Insane, heh?

What about stopping with this waste of CPU cycles and cleaning the data once and for all?

Don't worry, you don't have to do anything, it's already done and sorted out for you with this dead simple plugin. The params_sanitizer plugin uses Rails own sanitizers to clean the user input when it's first provided on form POSTs and PUTs (what? do you change your application/database state with GET calls? OMFG!). You can protect all calls to all controllers, protect all actions in a single controller and even protect specific actions in a single controller, it's your call!

First step is to install the <a href="http://github.com/mauricio/params_sanitizer">plugin</a>:

<pre class="brush:shell">ruby script/plugin install git://github.com/mauricio/params_sanitizer.git</pre>

With the plugin installed, you can start cleaning up user input in your application once and forgetting about it forever, here are the examples:
Stripping tags from all params in all actions (remember, only POST or PUT actions will really be changed ):

<pre class="brush:ruby">class ApplicationController &lt; ActionController::Base
  strip_tags_from_params #strip_tags users rails full_sanitizer
end</pre>

Stripping tags from all params for all actions in a single controller:

<pre class="brush:ruby">class NewsStoriesController &lt; ApplicationController
  strip_tags_from_params
end</pre>

Stripping tags from all params for specific actions in a single controller:

<pre class="brush:ruby">class CommentsController &lt; ApplicationController
  strip_tags_from_params :only =&gt; [ :create, :update ]
end</pre>

If instead of stripping all tags, you'd just like to use the simple sanitizer  (it removes bad tags like  but would leave others intact, uses rails white_list_sanitizer):

<pre class="brush:ruby">class ApplicationController &lt; ActionController::Base
  sanitize_params
end

class NewsStoriesController &lt; ApplicationController
  sanitize_params
end

class CommentsController &lt; ApplicationController
  sanitize_params :only =&gt; [ :create, :update ]
end</pre>

This plugin depends only on Rails default sanitizers, so you don't need to install anything else to have it working.

Now, as the data is cleanly stored in your database, you don’t have to waste CPU cycles cleaning up data in your view layer (and you can even say that you’re more adherent to the MVC, as cleaning up user input was never one of it’s jobs).
