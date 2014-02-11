---
layout: post
title: Setting a far future expires header for your Rails app static assets in your
  Nginx server
tags:
- outdated
---

Setting a far future expires header for your static assets is one of the first front end performance improvements you must do in your web applications. This will tell your user’s browser to keep the static assets cached and they won’t make unnecessary HTTP requests just to see that the version they currently have is already the latest and this will surely improve your website’s perceived performance (yes, there’s a REAL and a user perceived performance for every application).

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
