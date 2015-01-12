---
layout: post
title: Implementing Enumerable in Ruby
subtitle: an abstraction exercise
keywords: ruby, collection, enumerable, data structures, array
tags:
- useful
- ruby
---

Ruby's [Enumerable](http://ruby-doc.org/core/Enumerable.html) is, by far, one of the greatest examples of how modules should be made. It offers a large collection of methods that are useful for those handling collections and only requires you to implement a single method, `each`. So, any class that could behave like a collection and implement an `each` method can be used as an `Enumerable`.

A nice exercise to understand how `Enumerable` works is implementing it's main methods. By implementing each method ourselves, we understand better what each one of them is doing and how it was possible to build this much functionality requiring only a single method to be implemented.

# `map`

The documentation for `map` says:

> Returns a new array with the results of running block once for every element in enum.

{% highlight ruby %}

{% endhighlight %}






...
