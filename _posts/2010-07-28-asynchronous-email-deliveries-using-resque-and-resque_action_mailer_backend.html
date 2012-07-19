---
layout: post
title: Asynchronous email deliveries using Resque and resque_action_mailer_backend
tags:
- en_US
- rails
- redis
- resque
- ruby
- ruby on rails
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  jabber_published: '1280289583'
  _wp_old_slug: ''
  delicious: s:78:"a:3:{s:5:"count";s:1:"7";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1281725943";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1295404654";}";
  dsq_thread_id: '217521100'
  _su_keywords: queue, deployment, asynchronous, email, ruby, rails, resque, scalability,
    offload, redis
  _su_description: Learn how to easily send emails in a background process from your
    Rails application using your already available Resque queue.
  _su_rich_snippet_type: none
  _su_title: Asynchronous email deliveries using Resque and resque_action_mailer_backend
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:3;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:4;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:5;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:6;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:7;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
---
[caption id="attachment_154" align="alignleft" width="120" caption="The Rails 3 Way"]<a href="http://www.amazon.com/gp/product/0321601661?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=0321601661"><img src="http://techbot.me/wp-content/uploads/2011/01/rails3.jpg" alt="The Rails 3 Way" title="The Rails 3 Way" width="120" height="160" class="size-full wp-image-154" /></a>[/caption]<strong>Check the GitHub repo <a href="http://github.com/mauricio/resque_action_mailer_backend">here</a> and a sample application using it <a href="http://github.com/mauricio/resque_action_mailer_backend_example">here</a>.</strong>

If you have ever sent emails using ActionMailer during a user request you probably noticed that if the email sending fails or takes too long your user might not be really happy with the speed of your application. Making the email sending process an asynchronous one is usually the simplest solution for this problem and there are plenty of tools to do that like ar_mailer, that stores emails in your database and then uses a specific daemon to send them.

<!--more-->

<a href="http://seattlerb.rubyforge.org/ar_mailer/">ar_mailer</a> and other solutions are quite enough for most of your problems but what if you’re already using Resque to run your asynchronous jobs? Why bother using yet another daemon to do the email sending jobs with all the hassle of managing if you can use your current Resque setup to do it?

With this in mind I sat a bit and wrote this simple gem that lets you do exactly that, send your emails asynchronously using a Resque worker and without changing a single line of your email sending code. Following the same philosophy of ar_mailer, the resque_action_mailer_backend doesn’t require you to call fancy methods on your mailers, you just keep them as they are now and instead of changing them you just change the delivery method to :resque, like this (in a environment file, like “development.rb”):

<pre class="brush:ruby">config.action_mailer.delivery_method = :resque</pre>

The gem uses your ActionMailer::Base.smtp_settings configuration to deliver the emails, so you don’t have to change anything in there, just be sure that the SMTP credentials are correct so the worker can deliver emails without issues. The default queue name is “:headbanger_resque_mailer”, but you can change it to whatever you’d like to with this code:

<pre class="brush:ruby">Headbanger::ResqueMailer.queue = :your_email_queue</pre>

This single line of code changed will now make all your emails be queued to Resque and they’ll be sent as soon as a worker is available for it. Now you only have to tell your rails application to load the resque_action_mailer_backend gem (in your environment.rb):

<pre class="brush:ruby">config.gem &quot;resque_action_mailer_backend&quot;</pre>

You can check a some hints on using this setup at <a href="http://github.com/mauricio/resque_action_mailer_backend_example">this sample project</a>.

And you’re ready to start sending emails asynchronously using your resque workers!

Enjoy!
