---
layout: post
title: Functional thinking in Ruby
subtitle: one step at a time
keywords: ruby, scala, functional programming, enumerable, map, fold, inject
tags:
- ruby
- scala
- useful
---

I was going over Ruby questions on SO one of these days and [clicked one without any snwers](http://stackoverflow.com/questions/25033912/convert-array-into-a-hash/25037634#25037634),  reading it, the `shift` calls while operating in the `group_by` block were already painted red in my mind. That can't be right, **why change the items you're operating on?**

Also, it didn't look like a good case for `group_by`, that could definitely be implemented with  `inject` in a much simpler way. And here I start to write the solution I thought was much cleaner using `inject` instead of operating and mutating stuff in place:

{% highlight ruby %}
a = [ [1, 0, "a", "b"], [1, 1, "c", "d"], [2, 0, "e", "f"], [3, 1, "g", "h"] ]

result = a.inject({}) do |acc,(a,b,c,d)|
  acc[a] ||= {}
  acc[a][b] = [c,d]
  acc
end  
{% endhighlight %}

Later, reading the comments at the question and all answers, I finally noticed there actually wasn't anything wrong with any of them. A couple years ago, I would have written them the same way (I definitely have Java and Ruby code lying around here like that) and wouldn't even blink, it works, it's readable, why did it bug me this time?

Just like it became natural for me to use closures all over the place in Ruby, looks like immutability, maps and folds are now the de-facto standard for the way I write my code as well.

## Don't change what isn't yours

The first thing that did bug me was the `shift` calls. Following the best practices in the community, I've always tried to use as much immutable objects in Scala as possible. Anything that could be made a `val` (a constant) was, what couldn't be was at least hidden as much as possible from external users of the code as possible and this has translated nicely to the code I'm writing in Ruby, C# or others I happen to work on.

[As I mentioned at my previous post]({% post_url 2014-07-27-mutability-strikes-again %}), mutating stuff can easily lead to weird side effects in your code and you might not find them until it's too late. In the case of transforming a data structure into something else, this is even more complicated because it's hard to know who owns the structure you're operating on. Is it my code, the one doing the transformation? Is it whoever is calling me? And what happens with what I have returned? Do I own that or does it also belong to whoever made the call?

All of these ownership questions stop making sense once you go immutable or at least assume immutability is the goal. And while it's not fully natural to do it in Ruby, doing it isn't complicated either, you just have to **shift** your thinking.

Whenever you take parameters, assume they're **not** yours. Don't include new stuff or delete parts of it, if you need to operate on it and it's a collection, use one of the many operations that produce a new collection or value like `map`, `inject` and `zip`.
