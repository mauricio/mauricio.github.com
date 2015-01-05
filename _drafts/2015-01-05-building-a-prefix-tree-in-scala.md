---
layout: post
title: Building a prefix tree (or trie) in Scala
subtitle: add, search and remove
keywords: scala, strings, taming text, prefix tree, trie, data structure
tags:
- useful
- scala
---

Following up on my [new year's resolutions]({ post_url 2014-12-25-technology-to-learn-for-2015 }), I've been reading [Taming Text](http://www.manning.com/ingersoll/) and there's quite a lot of interesting stuff there, one of them is the prefix tree.

[Prefix trees (or tries)](http://en.wikipedia.org/wiki/Trie) are a very efficient way to store collections of words so you can search for them by their prefixes (or suffixes if you revert the strings). You can use them to produce predictive lists for auto-complete solutions, dictionaries or any solution where you need to quickly access collections of words (or any type of value, as long as it's keyed by a string) that start with a given prefix.

## Defining the operations

Let's see which operations we would like our trie to implement:

{% highlight scala %}
sealed trait Trie extends Traversable[String] {

  def append(key : String)
  def findByPrefix(prefix: String): scala.collection.Seq[String]
  def contains(word: String): Boolean
  def remove(word : String) : Boolean

}
{% endhighlight %}

First, our trie is a `Traversable[String]`. The only thing `Traversable[T]` requires is a `foreach` method and we can easily implement one for our data structure. Being a `Traversable[T]` means our trie can interact with many of the other collections declared at the standard library (and this will be useful at our implementation later). When building new data structures in Scala, it's often good to make sure they implement one of the base collection traits to simplify their interoperability with the standard library.

Then we have the methods we need for our trie, `append` to add a new word, `findByPrefix` to list all words known that start with the given prefix






...
