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
private[trie] class TrieNode(
  val char : Option[Char] = None,
  var word: Option[String] = None) extends Trie {
  private[trie] val children: mutable.Map[Char, TrieNode] =
    new java.util.TreeMap[Char, TrieNode]().asScala

}
{% endhighlight %}

`Option` twice!

Yes, that's it. The very first node at our tree represents the _empty char_ and since there is no _empty char_ we just make it an `Option` object since it could then be a `None` to signal this is the _empty char_ (if you don't know what `Option` is, [check this out]({% post_url 2013-12-25-learning-scala-by-building-scala-lists-part-3 %}) ).

Also, the node might be a *word node* or not. What does it mean to be a *word node*? A word node is one that represents a word that was included in the prefix tree. Let's look at the tree structure we have here:

    j
      o
        a
          b
        ã
          o

Here we have a tree with two names, _joão_ and _joab_, if we include another name like _joão paulo_, how do we remember that _joão_ was a name as well?

To make sure we don't forget the names, we have to also mark the tree nodes as *word* nodes, so we know that we have a word for that part of the tree even if this node has children that forms other words as well. So, that's the reason why we have this second `Option` field at the `TrieNode` object.

The structure also maintains a list of it's own children so we can continue traversing the tree structure. Given *Scala* does not provide a mutable `TreeMap` data structure, we create a *Java* `TreeMap` object and wrap it as if it was a `Scala` _mutable map_ (with the `asScala` method from `scala.collection.JavaConverters`). The use of `TreeSet` here helps us make the traversal in the tree follow the lexicographic order for the stored words.

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

## Finding words by their prefix

This is where the prefix tree really becomes useful, when you have to find words by their prefix. What we do here is we take a prefix and find every word that happens to match the prefix given, with a common hash structure you would have an `O(1)` (a single operation) to find a specific item by key, but you wouldn't have a way to find all items that have a key that start with *bar* and this is where tries are useful.

Let's look at our implementation:

{% highlight scala %}
override def findByPrefix(prefix: String): scala.collection.Seq[String] = {

  @tailrec def helper(currentIndex: Int, node: TrieNode, items: ListBuffer[String]): ListBuffer[String] = {
    if (currentIndex == prefix.length) {
      items ++ node
    } else {
      node.children.get(prefix.charAt(currentIndex).toLower) match {
        case Some(child) => helper(currentIndex + 1, child, items)
        case None => items
      }
    }
  }

  helper(0, this, new ListBuffer[String]())
}  
{% endhighlight %}

Now we are traversing towards a specific path of nodes in our tree, we only want the nodes that match the character we have at every index (all characeters are also lowercased). This could lead us to two cases, one where we have found the character (and then continue deeper) and one were one of the characters in the prefix does not match. As soon as we fail to match (the `None` case) we return. Otherwise, if we reach the end of the string we append all words under that node to the accumulator list.

Again, this is `foreach` and `Traversable[T]` in action. The `++` method at `ListBuffer` couldn't possibly kno what to do with our `TrieNode` object, but since we have extended the `Traversable[T]` trait and implemented `foreach` it can just use the methods available and pull all the items from that part of the tree and down. We don't have to actually collect the items, the `++` method will already do the collection work for us and include the words at and below the current item.

Let's look at an example with a trie that contains `johann`, `john` and `joan`:

    j
      o
        a
          n # word node
        h # this is the current node
          a
            n
              n #word node
          n # word node

The node with the `h` is the one at `if (currentIndex == prefix.length)` when we make a search by `joh`, so, once we call `foreach` on it, this is the beginning of our tree now, only the words that are inside or below it will be returned. In this case, it would return `john` and `johann` but not `joan` because `joan` is not under the node that contains `h`.

And again the method uses an internal tail recursive helper function to do it's job so we don't blow the stack when trying to find all words that match the prefix.

## A not very efficient `contains`

`contains` is implemented here mostly for completeness, but this is not exactly what you want to do with a prefix tree. If your actual use case is to figure out if whole words are inside a collection, a `Set` is a much better solution since it will usually require a single operation to give you this information while the worst case scenario for the `trie` is going to be `O(N)` where `N` is the size of the string you're looking for.

Let's look at the implementation:

{% highlight scala %}
override def contains(word: String): Boolean = {

  @tailrec def helper(currentIndex: Int, node: TrieNode): Boolean = {
    if (currentIndex == word.length) {
      node.word.isDefined
    } else {
      node.children.get(word.charAt(currentIndex).toLower) match {
        case Some(child) => helper(currentIndex + 1, child)
        case None => false
      }
    }
  }

  helper(0, this)
}  
{% endhighlight %}

As you can see from the code, the best case will be `O(1)` (a single operation) if not even the first character is included in the tree, but if the word is included or if it is the prefix for a word that is included, the code performs as many operations as there are characters in the string.

A simple solution for a faster contains could be having a `Set` that holds all words inside the prefix tree, but this is beyond our scope here. Also, we could assume that this implementation could be simplified if we used the `findByPrefix` method and checked if the word was included in the resulting list. While this is indeed possible, it would require many more operations as `findByPrefix` finds *all* words at and below the prefix, while our contains only cares about the exact prefix match.

Still, we could abstract the way they traverse the tree as it is exactly the same and avoid repeating the traversal code, which is something we will do for the `remove` operation.

## Removing items from the trie

This is arguably the most complicated piece of our trie implementation, removing an item from a trie is an expensive operation and at it's worst case will require `O(2N)` operations where `N` is the size of the string being removed. The implementation is complicated because we must build a direct path of nodes until the actual word node we're looking for and then we must travel this path backwards removing all the empty nodes, usually stopping when we find another word node.

Let's look at an example:

    j
      o
        h
          a
            n
              n #word node
          n # word node
            n
              a
                u
                  r #word node


Here we have a tree with the names `johann`, `john` and `john naur`. If we remove `john naur` we have to remove the whole `naur` suffix but leave `john` untouched since we also have `john` as an actual name, so what needs to happen is that we need to reach that last `r` node, walk up to `u`, delete the reference to the `r` node at it's children, this will make `u` not have any children and since it isn't a word node it means that we have to remove it, we keep repeating this until we reach the `n` that is the end of `john`, we again delete the reference to the `n` node for `naur` that is on it and since this node is  a word node our delete process has to stop.

As you can see, deleting a word from our prefix tree is a quite complicated operation. As with `contains`, you're better off if you build the tree and avoid removing items from it.

The delete operation is divided into two pieces, the first is to build the full path until the word node that is being deleted:

{% highlight scala %}
private[trie] def pathTo( word : String ) : Option[ListBuffer[TrieNode]] = {

  def helper(buffer : ListBuffer[TrieNode], currentIndex : Int, node : TrieNode) : Option[ListBuffer[TrieNode]] = {
    if ( currentIndex == word.length) {
      node.word.map( word => buffer += node )
    } else {
      node.children.get(word.charAt(currentIndex).toLower) match {
        case Some(found) => {
          buffer += node
          helper(buffer, currentIndex + 1, found)
        }
        case None => None
      }
    }
  }

  helper(new ListBuffer[TrieNode](), 0, this)
}
{% endhighlight %}

We provide a list buffer to be filled with nodes and we then traverse the tree to buid the actual list, if we reach the end of the word we're looking for and it is indeed a *word node* then we return the list, if it isn't we just return `None` to signal that we haven't found the full word we're looking for. It's important here that we only return if we do find a word node that matches, otherwise we could be deleting parts of other words.

Then, with the method that builds the path, we can implement the `remove` operations:

{% highlight scala %}
override def remove(word : String) : Boolean = {

  pathTo(word) match {
    case Some(path) => {
      var index = path.length - 1
      var continue = true

      path(index).word = None

      while ( index > 0 && continue ) {
        val current = path(index)

        if (current.word.isDefined) {
          continue = false
        } else {
          val parent = path(index - 1)

          if (current.children.isEmpty) {
            parent.children.remove(word.charAt(index - 1).toLower)
          }

          index -= 1
        }
      }

      true
    }
    case None => false
  }

}
{% endhighlight %}

The `remove` method ended up being imperative mostly because it's easier to understand, what we do here is first mark the last node (the word node) as not being a word node anymore and we keep going for the parent of the current node and removing the current node from it if it does not have any children. This is done because if the current node has no children and it isn't a word node, it is part of the word we're removing so it should be taken out as well.

## The trie is done

And with this we end our trie (or prefix tree) implementation, as you can see from our implementations, if you need to quickly find words given a prefix, this is a great data structure to use, specially if most of what you will be doing is including words and then trying to find them.

If you actually need to match full words or you need to perform many inclusions and removals, this might not be the best option for you.

The full source for the `trie` implementation is [here](https://github.com/mauricio/scala-sandbox/blob/master/src/main/scala/trie/Trie.scala) and the spec is [here](https://github.com/mauricio/scala-sandbox/blob/master/src/test/scala/trie/TrieSpec.scala).
