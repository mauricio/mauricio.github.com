---
layout: post
title: Accessing the current request object on your mailer templates to generate links
tags:
- en_US
- ruby
- ruby on rails
status: publish
type: post
published: true
meta:
  _su_description: ''
  _edit_last: '1'
  delicious: s:78:"a:3:{s:5:"count";s:1:"3";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1281482615";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1295161457";}";
  dsq_thread_id: '218397875'
  _su_keywords: ''
---
A common issue with mailer templates is that as they’re not being called from a controller you can’t get your hands on the request object and access properties like <strong>host_with_port</strong>. While you’re usually calling the mailers inside controllers and you could possibly hand the request as a parameter to it, it isn’t really nice to do this every time you need to send an email.

<pre class="brush:plain">&lt;%= link_to 'Home', "#{current_request.protocol}#{current_request.host_with_port}/home" %&gt;</pre>

So, if you’re looking for a quick and easy solution to this issue, the <a href="http://github.com/mauricio/current_request/tree/master">current_request</a> plugin is your friend, you can install it by calling:

<code>ruby script/plugin install git://github.com/mauricio/current_request.git</code>

The plugin works by setting the current request in a thread local variable that will be available until the end of the request, which means that you can use it safely in your templates, two new methods are added to all views, <strong>current_request</strong>, that returns, obviously, the current request being answered and <strong>current_host</strong> that will build the current host with port and protocol for you. Examples:

Or you can just use a shorthand to the current host:

<pre class="brush:plain">&lt; %= link_to 'Home', "#{current_host}/home" %&gt;</pre>

You can also use it wherever you want to access the current request (and not only on templates) by calling:

<pre class="brush:ruby">CurrentRequest::Holder.current_request</pre>
