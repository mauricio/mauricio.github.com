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

Then we have the methods we need for our trie, `append` to add a new word, `findByPrefix` to list all words known that start with the given prefix, `contains` to check if we have the *word* included at our structure and finally `remove` to remove a word from it.

## The `TrieNode` data structure

The prefix tree, as the name implies, is built in the form of a tree data structure where every node represents either the _empty char_ (the root node) or a single character in a word. The nodes here might or might not contain children and they can also be a _word node_, meaning that the path of characters that lead to this specific node form an actual word included at the prefix tree.

Let's look at the structure:

{% highlight scala %}
private[trie] class TrieNode(val char : Option[Char] = None, var word: Option[String] = None) extends Trie {
  private[trie] val children: mutable.Map[Char, TrieNode] = new java.util.TreeMap[Char, TrieNode]().asScala

}
{% endhighlight %}

`Option` twice!

Yes, that's it. The very first node at our tree represents the _empty char_ and since there is no _empty char_ we just make it be an `Option` object since it could then be a `None` (if you don't know what `Option` is, [check this out]({ post_url 2013-12-25-learning-scala-by-building-scala-lists-part-3 }) ).

Also, the node might be a *word node* or not. What does it mean to be a *word node*? A word node is one that represents a word that was included in the prefix tree. Let's look at the tree structure we have here:

    j
      o
        a
          b
        ã
          o

Here we have a tree with two names, _joão_ and _joab_, if we include another name like _joão paulo_, how do we remember that _joão_ was a name as well?

To make sure we don't forget the names, we have to also mark the tree nodes as *word* nodes, so we know that we have a word for that part of the tree even if this node has children that forms other words as well. So, that's the reason why we have this second `Option` field at the `TrieNode` object.

The structure also maintains a list of it's own children so we can continue traversing the tree structure. Given *Scala* does not provide a mutable `TreeSet` data structure, we create a *Java* `TreeSet` object and wrap it as if it was a `Scala` _mutable map_ (with the `asScala` method from `scala.collection.JavaConverters`). The use of `TreeSet` here helps us make the traversal in the tree follow the lexicographic order for the stored words.

## `append` and `foreach`

We have to talk about these two methods together because it's really hard to test one without the other. Let's look at `append` first:

{% highlight scala %}
override def append(key: String) = {

  @tailrec def appendHelper(node: TrieNode, currentIndex: Int): Unit = {
    if (currentIndex == key.length) {
      node.word = Some(key)
      } else {
        val char = key.charAt(currentIndex).toLower
        val result = node.children.getOrElseUpdate(char, {
          new TrieNode(Some(char))
          })

          appendHelper(result, currentIndex + 1)
        }
      }

  appendHelper(this, 0)
}
{% endhighlight %}

The first thing to take note here is that since we're dealing with a recursive data structure, most of our methods will be implemented in a recursive way. The goal of the `append` method is to create a new node for every letter at our provided *word* that does not exist at our tree and then mark the last node as a _word node_.

For instance, imagine our tree only had *john* included:

    j
      o
        h
          n

Once we try to include *jane*, the tree then becomes:

    j
      a
        n
          e
      o
        h
          n

Both words share the *j* node, but then they diverge to their own subtrees to form their own words.

And since we're dealing with recursion, we need to make sure our program won't blow the stack by doing too many recursive calls. To do that, we've included the `appendHelper` function and tagged it with the `@tailrec` annotation that will require the method to be written in a way that makes it possible to apply the tail call optimization. The requirement is that the function has to call itself only at a _tail position_ or that it can only call itself as the last operation in a branch.

This is exactly what we do, `appendHelper` is only called at the end of the `else` block and hence this method can be optimized and will not cause a stack overflow. Since this function is only usable by the `append` method, there's no need to move it out, we can just have it here and not leak this implementation detail.

Now let's look at the `foreach` function:

{% highlight scala %}
override def foreach[U](f: String => U): Unit = {

  @tailrec def foreachHelper(nodes: TrieNode*): Unit = {
    if (nodes.size != 0) {
      nodes.foreach(node => node.word.foreach(f))
      foreachHelper(nodes.flatMap(node => node.children.values): _*)
    }
  }

  foreachHelper(this)
}  
{% endhighlight %}

This is much simpler than `append`, all the code has to do is to take the function provided as parameter and call it on every _word node_. Since the `word` object is itself an `Option`, we can just call `foreach` at the `Option` object and it will do the right thing.

Again, we have an internal helper function that actually does the work and is made to be tail call optimized. It's important to have the stop condition around the actual code here, to make sure we don't even bother calling `foreach` if we don't have any items, otherwise the code would loop forever.

The only interesting bit here is that we make the `foreachHelper` method take a `vararg` so we can call it with any number of parameters, this guarantees we can make it optimizable since we can make the first call with a single parameter and then call it again at the tail of the method with the child collection for the current node.

Here's how these two methods are used:

Here's how we use it:

{% highlight scala %}
"include a word" in {
  val trie = new TrieNode()
  trie.append("Maurício")

  trie must contain("Maurício")
}  
{% endhighlight %}

Here we can clearly see `append` in use, but where is `foreach`?

`foreach` is in use at the `contain` matcher here. The `contain` matcher expects to find a collection where it can iterate and try to find the value we're asking for. So, while we didn't implement methods to figure out if we can find that item, the fact that we have implemented `foreach` and our `Trie` inherits from the `Traversable` trait provides us with a lot of functionality for free.




...
