---
layout: post
title: If you’re cleaning up your user’s input in your views you’re doing it wrong
tags:
- outdated
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
