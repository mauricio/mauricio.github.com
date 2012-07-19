---
layout: post
title: Handling various rubies at the same time in your machine with RVM – Ruby Version
  Manager
tags:
- bundler
- en_US
- rails
- ruby
- rvm
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  jabber_published: '1295976893'
  email_notification: '1295976894'
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1296165627";}";
  dsq_thread_id: '217521119'
  _su_keywords: ruby, rails, rvm, linux, mac, environment, development, ree, deployment,
    bundler, gemset
  _su_description: When you're working on various Ruby projects at the same time,
    it pays not to have everything installed on the same environment and also be able
    to try out something new without breaking your installation. And that's where
    RVM comes to the rescue.
  _su_rich_snippet_type: none
  _su_title: Handling various rubies at the same time in your machine with RVM – Ruby
    Version Manager
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:2;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:3;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:4;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:5;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:6;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:7;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
---
[caption id="attachment_160" align="alignleft" width="122" caption="Dig deeper into Ruby with this book"]<a href="http://www.amazon.com/gp/product/0596516177?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=0596516177"><img class="size-full wp-image-160" title="Dig deeper into Ruby with this book" src="http://techbot.me/wp-content/uploads/2011/01/ruby1.jpg" alt="Dig deeper into Ruby with this book" width="122" height="160" /></a>[/caption]

If you’ve been working in Ruby for more than a year you have probably seen a lot of changes in the landscape. We saw a lot of gems adding compatibility layers to run on Ruby 1.9.2, Rails 3 was finally released (also supporting 1.9.2) and new gems using 1.9.2 features are also showing up.

But guess what? You’re stuck at 1.8 (1.8.7 if you’re lucky) for a lot of projects and you’re in deep fear that installing the latest Ruby 1.9.2 to try all these new fancy things is going to wreak havoc on your environment and you’re going to be <a href="http://en.wikipedia.org/wiki/FUBAR">FUBAR</a>.

Worse, you still have projects running on Ruby 1.8.6 (with that nasty SMTP-TLS bug) and if you upgrade to a newer Ruby you might have false positives in your codebase and things are going to break in production. You’re already FUBAR, you might think.

But fear not! There’s a knight in shiny armor riding for his damsel in distress! (yes, YOU) And this knight is <a href="http://rvm.beginrescueend.com/">RVM</a>!

<!--more-->

RVM is a set of bash scripts, written by <a href="http://twitter.com/#!/wayneeseguin">Wayne E. Seguin</a> (and others) that allows you to do just that, install various different Rubies on your machine in a way that they do not conflict with each other. You can even go farther and install different “gem groups” for every project you have so that each one lives in it’s own sandbox without breaking the dependencies or installing gems that are needed for only one application.

Here you’ll learn to setup, install and do the basic workflow when using RVM on your daily development.

<h3>Installing RVM</h3>

First make sure that your system has a sane build environment by installing compilers/make/whatever it is needed in your OS to build source code. If you’re on an Ubuntu machine, the “build-essential” package should do it, on a Mac it’s the XCode Unix Tools. Once you’re done with that, install Git and from a console type:

<pre class="brush:shell">bash &lt;&lt; ( curl http://rvm.beginrescueend.com/releases/rvm-install-head )</pre>

Once finished, open up your “.bash_profile” (or equivalent) and append this to the end of it:

<pre class="brush:shell">[[ -s "$HOME/.rvm/scripts/rvm" ]] &amp;&amp; . "$HOME/.rvm/scripts/rvm"</pre>

Close your console and open it again, type “rvm -v” and you should see the version info for your RVM install.

<h3>Installing Rubies</h3>

Once you have RVM ready, the first thing to do is to start installing the rubies you’ll want to use. Different than what you might be used to, RVM installs the rubies and gems in your user’s directory (under “~/.rvm”), so you will NEVER use “sudo” when installing anything with RVM. Everything is always installed in your user’s home directory (you could possibly install RVM as root, but you <strong>DO NOT WANT </strong>to do that, trust me).

Let’s start by installing Ruby 1.8.7, Ruby 1.9.2, <a href="http://www.rubyenterpriseedition.com/">Ruby Enterprise Edition</a> and <a href="http://www.jruby.org/">JRuby</a>:

<pre class="brush:shell">rvm install ruby-1.8.7,ruby-1.9.2,ree,jruby</pre>

This is going to take a while as RVM is going to pull the source code for all these rubies and build them in your environment. Once it’s over, tell RVM which one is your “default” Ruby (the one that’s going to be loaded by default on your consoles). Let’s use “ruby-1.8.7” as the default:

<pre class="brush:shell">rvm  --default ruby-1.8.7</pre>

Now, every console that opens up will use the Ruby 1.8.7. If you want to switch to another Ruby, here’s how you’d do it:

<pre class="brush:shell">rvm ruby-1.9.2</pre>

To see which Rubies you have installed currently:

<pre class="brush:shell">rvm list</pre>

<h3>Installing gems</h3>

Before start installing gems you should probably fine tune your “~/.gemrc” file by telling Rubygems not to generate “ri” or “rdoc”, this will absurdly speed up gem installs (unless you really want that). Here's my "~/.gemrc" file (the most important configs are "install" and "update"):

<pre><code>---
:verbose: true
:bulk_threshold: 1000
install: --no-ri --no-rdoc --env-shebang
update: --no-ri --no-rdoc --env-shebang
:sources:
- http://gemcutter.org
- http://gems.rubyforge.org/
- http://gems.github.com
:benchmark: false
:backtrace: false
:update_sources: true</code></pre>

Now that you’re done, each Ruby that you installed comes with it’s own separate Rubygems environment, which means you can install gems in one Ruby and it isn’t going to affect the other ones. With RVM you can even go further and define “gemsets” that are groups of gems that are independent even from the “main” gems available for that specific Ruby.

The way you’ll work with your rubies and gemsets depends on what you really want. I, personally, love to have a gemset for every single application and that’s what I’m going to talk about now, I hope this workflow works for you too.

First thing to do is to define which are the most common needs you’re going to have using these rubies. In my case, I have Ruby 1.8.7 for my Rails 2.3 projects, so I’ll install Rails and some other common gems on it:

<pre class="brush:shell">rvm  ruby-1.8.7
gem install rails –v 2.3.10
gem install will_paginate nokogiri mysql sunspot sunspot_rails</pre>

Install here only the gems you believe you’re going to use on most of your projects.

Now I’d like to have the Ruby 1.9.2 for Rails 3 development, so I’m going to install the latest Rails on it:

<pre class="brush:shell">rvm ruby-1.9.2
gem install rails nokogiri mysql2</pre>

Once you have the “base” gems ready for every Ruby, you can start defining “gem sets” for your projects. The best way to do this is to create a “.rvmrc” file at the root directory of every project, here’s how the file would look like:

<pre class="brush:shell">rvm ruby-1.9.2@my_application --create</pre>

Once you enter the directory that has the “.rvmrc” file, RVM will look at it and ask you if you want to “trust” the file, once you select “yes”, it’s going to create the gemset named in this file (in our case “my_application” using Ruby 1.9.2). RVM automatically switches to the Ruby and the gemset defined in the file whenever you enter the directory, you don’t have to do anything.

Now, if you run a “gem list” inside this directory you’ll see that there are only two gems in this gemset, “bundler” and “rake”. Not really super, right? But we have already installed Rails 3 in the main Ruby 1.9.2 path, so we can easily migrate them to this new gemset, here’s how you’d do it:

<pre class="brush:shell">rvm gemset copy ruby-1.9.2 ruby-1.9.2@my_application</pre>

This will get all gems we placed in the base ruby-1.9.2 install and copy them over to our application’s gemset. You could even copy the gems from another gemset that you already have.

The beauty in using “.rvmrc” files and gemsets for you projects is that once you push this file to your source control system, everyone that accesses the project will be “forced” to have a gemset and it’s surely going to be easier to manage dependencies.

Also, if you’re combining RVM with <a href="http://gembundler.com/">Bundler</a> you’ll have a much more reliable and repeatable environment, you can just move this project anywhere, create the gemset, install the necessary gems with Bundler and just start coding.

<h3>Conclusion</h3>

RVM is one of those tools you MUST have in your toolset when writing Ruby applications, specially if you have to handle many different Rubies, projects or environments and don’t want to start growing white hair (or worse, LOSE your hair) while doing it.

<h2>Related Posts</h2>

<ul>
<li> <a href="http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/">Full text search in in Rails with Sunspot and Solr </a> </li>
<li> <a href="http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/">Deployment Recipes – Deploying, monitoring and securing your Rails application to a clean Ubuntu 10.04 install using Nginx and Unicorn</a> </li>
</ul>
