---
layout: post
title: Quick Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
  models
tags:
- useful
---
One of the things you’ll find in every rails application is links like this one:

{% highlight erb %}
<%= link_to user.login, user %>
{% endhighlight %}

Or maybe like this one:

{% highlight erb %}
<%= link_to user.login, user_path( user ) %>
{% endhighlight %}

Or maybe something ugly like this one:

{% highlight ruby %}
<%= link_to user.to_label, user_path( user ) %>
{% endhighlight %}

How about throwing all of them and just doing it like this:

{% highlight ruby %}
<%= link_to user %>
{% endhighlight %}

Cool, isn’t it?

Now “how can I do that” you ask, it’s dead simple. First, remember that every object responds to a method called “to_s” and this “to_s” method is defined as “a method that returns a string representation of your object” in most programming languages, including Ruby.

A string representation of your object is something human readable that would tell someone else what this object represents. “to_s” isn’t meant to be a debug like method, we already have “inspect” to do that, so why not put it to work and simplify our links?

At every ActiveRecord model in your application you’ll define a to_s method that returns one (or maybe more, if needed) attributes of your object as a string (if they’re not strings, turn them into strings and return). Let’s see how your user would look like:

{% highlight ruby %}
class User < ActiveRecord::Base
  validates_presence_of :login
  validates_uniqueness_of :login
  def to_s
    self.login
  end
end
{% endhighlight %}

I decided that the "login" method is the one that best represents the User object and it's also the one I want to use then someone else seers users on the website. They won't see their real names by default, but their logins.

Why is it better to do this with the "to_s" method instead of adding a “to_label” method to all objects? ‘Cos many helpers will already call the to_s method by default on your object (as we'll see with the link_to helper), so you just get full compatibility for free. Check out our new link_to implementation:

{% highlight ruby %}
module ApplicationHelper
  #sample link_to override that will generate urls for active_record objects by default
  #if the first parameter is an active_record object and you just want a link to it,
  # you can call it just like this:
  # <%= link_to user %>
  # the helper will take care of generating the correct url
  def link_to( *args )
    options = args.extract_options!
    if args.size == 1 && args.first.is_a?( ActiveRecord::Base )
      super( *([ args.first, args.first ] + [ options ]) )
    else
      super( *( args + [ options ] ) )
    end
  end
end
{% endhighlight %}

If there’s only one object (besides the options hash) and it is an ActiveRecord::Base instance, just use the object itself as the url parameter (the real link_to helper will call polymorphic_url on it automatically) and also use the object as the link_to label (the first parameter), this will call the to_s method on our user and the link will use it as the label.

What do you get with this?

A seamless and clear way of defining labels for your models (the “to_s” method is part of the core of the language anyway) and also a simpler way of generating links for your objects. Common methods for object labels are very important because you can never be sure if the property you’re using today as a label will be used forever. Using the “to_s” method as the default “label method” will allow you to change the label property at any time with almost no change to other parts of the code.
