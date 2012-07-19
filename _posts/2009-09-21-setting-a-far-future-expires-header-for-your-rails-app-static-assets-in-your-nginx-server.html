---
layout: post
title: Setting a far future expires header for your Rails app static assets in your
  Nginx server
tags:
- en_US
- front end performance
- nginx
- rails
- ruby
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1295404667";}";
  delicious: s:78:"a:3:{s:5:"count";s:1:"4";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1281482613";}";
  dsq_thread_id: '217521081'
  _su_keywords: ''
  _su_description: ''
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:1;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"1";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:2;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"1";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:3;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"1";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"1";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"1";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:6;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"1";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:7;a:4:{s:2:"ID";s:2:"59";s:10:"post_title";s:150:"Setting
    up your Ruby on Rails application in an Ubuntu Jaunty Jackalope (9.04) server
    with Nginx, MySQL, Ruby Enterprise Edition and Phusion Passenger";s:7:"matches";s:1:"1";s:9:"permalink";s:172:"http://techbot.me/2009/06/setting-up-your-ruby-on-rails-application-in-a-ubuntu-jaunty-jackalope-9-04-server-with-nginx-mysql-ruby-enterprise-edition-and-phusion-passenger/";}i:8;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"1";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:9;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"1";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}}
  _relation_threshold: '1'
---
[caption id="attachment_168" align="alignleft" width="122" caption="Even Faster Websites"]<a href="http://www.amazon.com/gp/product/0596522304?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=0596522304"><img src="http://techbot.me/wp-content/uploads/2011/01/faster.jpg" alt="Even Faster Websites - Everything you need to now to improve you website&#039;s front end performance" title="Even Faster Websites - Everything you need to now to improve you website&#039;s front end performance" width="122" height="160" class="size-full wp-image-168" /></a>[/caption]Setting a far future expires header for your static assets is one of the first front end performance improvements you must do in your web applications. This will tell your user’s browser to keep the static assets cached and they won’t make unnecessary HTTP requests just to see that the version they currently have is already the latest and this will surely improve your website’s perceived performance (yes, there’s a REAL and a user perceived performance for every application).

<!--more-->

Nginx isn’t as well known and used as Apache’s HTTPD but one of the most common deployment environment for Rails applications (specially after Phusion Passenger for Nginx) we clearly needed a simple solution for this expires header. Looking a little bit over the internet you can usually find a code sample just like this one:

<pre>location ~* \.(ico|css|js|gif|jpe?g|png)\?[0-9]+$ {
    expires max;
    break;
}</pre>

Looking at the regex you can surely figure out that you’re going to match any asset that ends with any of those extensions and has a timestamp (“?123456”) at the end. The timestamps are usually added by Rails asset helpers and they’ll clean up your user’s browser cache when the file is changed (if there’s no timestamp the cache will be cleared only when it’s full or you change the static asset name).

All good, right? Not so easy, cowboy. If you try to use this location directive you’ll never match anything. You might then end up with the following solution:

<pre>location ~* \.(ico|css|js|gif|jpe?g|png)(\?[0-9]+)?$ {
    expires max;
    break;
}</pre>

Now the timestamp is optional and you’ll finally start matching your static assets. But why wasn’t the previous directive working? Simple, the location directive will match only on the request filename, not on it’s query string. So, as there was never a timestamp, the first location would never set a far future expires header on anything. You should remove the timestamp match completely as it’s completely useless anyway.

But even this simple location directive has it’s own issues and they can easily bite you. We’re matching based on file extensions, so anything that ends with “.js” would be a match and would be served by Nginx, exactly what we want, right?

Maybe not. Imagine that you’re making a controller that responds to an HTML and an RJS view. The HTML view can be called by <strong>“/actions.html”</strong> and the RJS view can be called by <strong>“/actions.js”</strong>. When the browser calls <strong>“/actions.js”</strong>, Nginx looks at the extensions and thinks “hey, it’s a javascript file, I’ll handle it” and it sends a 404 error directly to your client, as this JS file doesn’t exist inside your public folder.

But you could use the HTTP request headers to tell your rails application that it’s a JS request, couldn’t you? Yep, but sometimes you can’t and you’d probably end up digging weird bugs and 404’s in production when you never saw them in your development machine. Not something really nice, I’d tell you.

And how do you get this sorted out? Instead of basing your rules in file extensions, you’ll do it using the folders where they live. In common Rails application images, javascript and stylesheet files have their own default folders and you would use a rule that matched on those folder names, just like the following:

<pre> location ~ ^/(images|javascripts|stylesheets|system)/  {
    expires max;
    break;
  }</pre>

The system folder is usually where you keep user generated data, like uploaded images, documents and things alike. With this simple location directive you’ll get all benefits from static asset caching on Nginx without worrying about crazy errors in your application. If you don’t plan to write a controller that answers to <strong>“/stylesheets/my_custom_theme.css”</strong>, obviously.
