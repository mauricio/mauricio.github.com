---
layout: post
title: Setting up your Ruby on Rails application in an Ubuntu Jaunty Jackalope (9.04)
  server with Nginx, MySQL, Ruby Enterprise Edition and Phusion Passenger
tags:
- deployment
- en_US
- linux
- nginx
- passenger
- ree
- ruby
- ruby on rails
status: publish
type: post
published: true
meta:
  _su_keywords: ''
  _edit_last: '1'
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1295161466";}";
  delicious: s:79:"a:3:{s:5:"count";s:2:"25";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1280621438";}";
  dsq_thread_id: '217521054'
  _su_description: ''
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"3";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:1;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"1";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:2;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"1";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:3;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"1";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"1";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"1";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:6;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"1";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:7;a:4:{s:2:"ID";s:2:"89";s:10:"post_title";s:89:"Setting
    a far future expires header for your Rails app static assets in your Nginx server";s:7:"matches";s:1:"1";s:9:"permalink";s:116:"http://techbot.me/2009/09/setting-a-far-future-expires-header-for-your-rails-app-static-assets-in-your-nginx-server/";}i:8;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"1";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:9;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"1";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}}
  _relation_threshold: '1'
---
There are many ways to deploy and run Ruby applications with the Ruby on Rails framework but it’s unlikely that you’re going to find a simpler and faster solution than using <a href="http://rubyenterpriseedition.com/">Ruby Enterprise Edition</a> (REE from now on) with <a href="http://wiki.nginx.org/">Nginx</a> and <a href="http://www.modrails.com/">Phusion Passenger</a>. Nginx is a fast, scalable and lightweight HTTP server, that is able to serve a lot of content without using up all your memory and Passenger is a module that can be tied into Apache or Nginx to handle your Ruby (and RoR) applications automatically.

When using Passenger you don’t need to worry about managing a pack of Mongrels or use a proxy HTTP server, Passenger lives inside your web server and just takes care of everything for you. Here you’ll learn how to use Passenger in conjunction with Nginx to deploy your applications in the wild.

This tutorial assumes that you’re building a brand new Ubuntu server with none or little custom packages installed. Does this mean you can’t use this with an already customized server? No, but it’s easier if you can follow it step by step to avoid problems, as this has already been tried and tested to be sure that it works. We’re using MySQL here because it’s what I’m using right now but can easily change the apt-get calls to use whatever database you’re using yourself.

<!--more-->

<h3>Setting up users</h3>

If you’re really starting up from a brand new install with no users created beyond the default ones you might want to create a user for yourself so that you don’t need to be logged in as a “root” forever. To create a new user in a Linux box the command is “useradd”:

<pre class="brush:shell">useradd -m -g staff -s /bin/bash mauricio</pre>

This will create a user called “mauricio” with a “/home/mauricio” home directory (as defined by the “-m” param), with “staff” as it’s default group and using  the “/bin/bash” shell. After creating a user for yourself you might also want to create a user for the application you’re deploying or a “deployment” user. This is the user that’s going to be used to deploy the application and run all application related processes. Just use the same command above changing the username to your deploy user, this can be the name of the application you’re deploying or just “deploy” (keep all your users belonging to the same "staff" group to avoid file permission issues when you edit or create files).

After doing this you can also make all users that belong to the staff group be able to use the “sudo” command. To do this just open the “/etc/sudoers” file with a text editor (I usually use “nano”) and add this line:

<pre class="brush:plain">%staff ALL=(ALL) ALL</pre>

<h3>Setting up your ssh keys</h3>

If you’re running in a Linux/Unix box and haven’t generated your SSH keys, it’s time to do it. If you have never heard of them, SSH keys can get you to login into servers where you have a user account without asking you for the password, which is really cool if you have to handle a lot of servers at the same time (and if you don’t want to type passwords every time you do a “git pull|git push”. To generate them do this as your local user in your local machine:

<pre class="brush:plain">ssh-keygen -t dsa</pre>

This command will create a folder called “.ssh” in your home directory (as in “/home/your_user/.ssh” with a bunch of files. It will ask you for a password to protect these files,  the password isn’t required but it’s nice to be cautious here as if you don’t set a password anyone with physical access to your machine (or can log in as you) could log in into all machines to where your SSH keys were copied to.

Now that the keys are already generated, you can copy them to the servers you usually log into, to do this, first log in to the server using  your account and at your user’s home folder create a .ssh folder:

<pre class="brush:plain">mkdir ~/.ssh</pre>

Log off and, from your local pc, copy the ~/.ssh/id_dsa.pub file to the remote machine using scp:

<pre class="brush:plain">scp ~/.ssh/id_dsa.pub your_remote_user@host:.ssh/authorized_keys2</pre>

This will copy your public key to the remote server and you’ll be able to log into that server from your current local machine and local user to the user you copied the key to in your remote server. You can obviously copy this to as many servers and user accounts as you like and none of them will ask you for a password again.

<h3>Getting Ubuntu up-to-date</h3>

First thing we need to do is to be sure that our server is up-to-date with the currently installed software:

<pre class="brush:plain">sudo apt-get update
sudo apt-get upgrade</pre>

Then we need to install some basic libraries and MySQL:

<pre class="brush:plain">sudo apt-get install build-essential mysql-server libmysqlclient15-dev libmagickcore-dev imagemagick  libpcre3 libfcgi-dev libfcgi0ldbl libxml2-dev libxslt1-dev -y</pre>

This is going to install the MySQL server, the ImageMagick library to handle image processing and the XML and XSLT libraries needed for some common gems like <a href="http://nokogiri.rubyforge.org/nokogiri/">Nokogiri</a>.

<h3>Installing Ruby</h3>

We’re not going to use the default Ruby interpreter that comes with Ubuntu but Phusions's Ruby Enterprise Edition. REE is a reliable and memory friendly fork of the main Ruby interpreter from the Phusion guys. <a href="http://www.rubyenterpriseedition.com/download.html">Go to the REE download page</a> and grab the “.deb” files for your architecture (look for the “Ubuntu Linux” tab). Install the “.deb” with:

<pre class="brush:plain">sudo dpkg -i path-to-the-deb-file</pre>

This will get REE installed to “/opt/ruby-enterprise” but the binaries will not be available at your PATH, we’ll need to add the “bin” dir to our PATH variable manually. Open up your “/etc/environment” file with your preferred command line text editor (mine is “nano”):

<pre class="brush:plain">sudo nano /etc/environment</pre>

And add the “/opt/ruby-enterprise/bin” dir to your PATH variable like this:

<code>PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby-enterprise/bin"</code>

This will get the scripts at the “bin” folder available to your user but not when you use “sudo” calls (Ubuntu just overrides the PATH when you call “sudo” for security reasons) so we’ll need to symlink some of the files to “/usr/bin” to be sure that they’re visible when you’re sudoing:

<blockquote>ln -s /opt/ruby-enterprise/bin/ruby     /usr/bin/ruby
ln -s /opt/ruby-enterprise/bin/gem     /usr/bin/gem
ln -s /opt/ruby-enterprise/bin/ri          /usr/bin/ri
ln -s /opt/ruby-enterprise/bin/rdoc     /usr/bin/rdoc
ln -s /opt/ruby-enterprise/bin/irb        /usr/bin/irb</blockquote>

Now let’s install some gems to be sure that everything is ok:

<pre class="brush:plain">sudo gem install rails mysql nokogiri rmagick mislav-will_paginate --no-ri --no-rdoc</pre>

The “--no-ri --no-rdoc” option is to avoid creating docs that we’re not really going to use and that will take a long time to be generated (also, if you’re into a VPS and don’t have a lot of memory those commands are surely going to throw out of memory errors). If you got no errors here, we’re good to go and install Nginx and Passenger.

<h3>Installing Nginx and Passenger</h3>

Installing Nginx with Passenger and Ruby EE is as easy as calling this command:

<code>sudo /opt/ruby-enterprise/bin/passenger-install-nginx-module --auto --auto-download</code>

Those “--auto” options are there to tell the installer that we’re saying yes to all defaults and we want it to download a brand new Nginx copy and build it with the Passenger module.  The installer is going to ask you where to install Nginx with a default of “/opt/nginx”,  just hit enter to get it installed at the default path.

As you can see from the messages printed, Passenger has already generated a sample configuration file with the basic config needed to run the application,  <a href="http://gist.github.com/126659">here’s an example of how it would look like</a>.

It’s VERY important to set the Nginx user to be the same user that’s going to deploy and create the application files as this will avoid permission issues that are one of the most common problems you're going to have. With Nginx configured to load your application, start it to be sure that everything is OK again:

<pre class="brush:plain">sudo /opt/nginx/sbin/nginx</pre>

Open up your browser pointing to the server where Nginx is running and you should see your application running correctly. If it isn’t, check the application logs and also Nginx error logs at “/opt/nginx/logs/error.log”. You can kill Nginx with a simple:

<pre class="brush:plain">sudo pkill nginx</pre>

<h3>Getting Nginx to run as a Daemon</h3>

Now that Nginx is running correctly and serving your application you need to set it up to run as a daemon. To do this we need to create a script that’s going to handle the Nginx daemon and install it using the update-rc.d utility. You can get the script <a href="http://gist.github.com/126656">here</a>.

You should save this script at “/etc/init.d/nginx” (sudo to do it), mark it as executable and install it as a daemon:

<pre class="brush:plain">sudo chmod +x /etc/init.d/nginx
sudo update-rc.d nginx defaults</pre>

Now when the machine reboots Nginx will be started automatically. As a last touch, start the Nginx daemon and your server is ready to roll:

<pre class="brush:plain">sudo /etc/init.d/nginx start</pre>
