---
layout: post
title: Learning Scala by building Scala - Lists Part 2
keywords: scala, lists, functional programming, monads, reverse, fold, filter, map, cons
tags:
- scala
- useful
---

Here we continue our journey to learn more about Scala and functional programming using lists. [If you haven't seen the first part of this tutorial]({% post_url 2013-11-25-learning-scala-by-building-scala-lists %}), you should probably read it first before reading this part. Now let's get back to learn more list operations.

The full source code for these examples can be found [here](https://github.com/mauricio/list-tutorial).

## Reversing a list

Reversing a linked list is a really simple solution given what we have built already, here's how it looks being used:

{% highlight scala %}
"Reverse a list" in {
  val original = LinkedList(1, 2, 3, 4, 5)
  original.reverse() === LinkedList(5, 4, 3, 2, 1)
}
{% endhighlight %}

The use of `()` here is mostly personal, I like to parenthesise the use of functions when they are building new objects instead of accessing already available information. You could remove the parenthesis from the method definition if you would like to and then you could remove them here when calling it.

Now let's get to the implementation:

{% highlight scala %}
def reverse() : LinkedList[E] = {
  foldLeft(LinkedList[E]()) {
    (acc, item) =>
      Node(item, acc)
  }
}
{% endhighlight %}

As you can see, the implementation is quite simple, to reverse a list you just `foldLeft` on it creating a new list on every element. Since `foldLeft` goes from left to right and `LinkedList` objects are built from right to left (first we have a tail and then we have the objects) this is the simplest algorithm possible.

The only weird thing we have is is the call to `LinkedList[E]()`, this is necessary because type inference for the compiler won't work if you use `Empty`, so we need to explicitly say we want to build an empty list of type `[E]`.

This is one of the beauties of functional programming, you just compose functions transforming values using the base building blocks provided to create new functionality.

## Folding to the right

Just as we had a `foldLeft` our list also needs a `foldRight` function that builds composes from right to left. **Why would we need something like that?**, you might think and the main reason is that not all binary operations are commutative. That is, the order of the operands affects the result of the operation.

When we used `foldLeft` to sum `LinkedList(1, 2, 3, 4, 5)` doing the sum from the left or right didn't matter, both `1 + 2 + 3 + 4 + 5` and `5 + 4 + 3 + 2 + 1` yield the same result. But what if it was a division? Is `4/2` the same as `2/4`? They're not and that's why we also need a function that composes from the right, we'll also see that we also need it to implement other functions in an efficient way, otherwise they wouldn't work for very large inputs and we will later re-implement `map` in terms of `foldLeft` for the same reason.

Let's see how we can implement `foldRight`:

{% highlight scala %}
def foldRight[B]( accumulator : B )(f : (E,B) => B) : B = {
  reverse().foldLeft(accumulator)((acc,item) => f(item,acc))
}
{% endhighlight %}

Now you must be thinking __come on, this is cheating__ but that's the most efficient way to implement a `foldRight` given our data structure. Since we don't have fast indexed access to elements (it's a singly linked list), we would have to recurse `N` levels (with `N` being the size of the list) to access the last element and then backtrack until the very first piece of the recursion.

As you can imagine, this would be very inefficient and also fail for large inputs with a stack overflow error so we just reverse the list (which is tail recursive since it uses `foldLeft`) and we `foldLeft` on the result. And folding to the left at the reverse of a list is, well, folding right. In this case, two lefts really make a right.

Also, in Scala, the `foldRight` function for collections reverse the arguments at the binary operation. While in a `foldLeft` the operation is `(accumulator,item)` in a `foldRight` it becomes `(item, accumulator)` so I have made it the same order here so you don't get confused when using the real `foldRight` in collections.

If you're into algorithms, you might say that instead of doing this stuff in `O(N)` time we now do it in `O(2N)` and this is true. Unfortunately, there aren't many options given the way our data structure is built, we gave up the `O(N)` time to allow our code to handle large inputs without overflowing. If you had a list with fast indexed access or a doubly linked list you would definitely be able to traverse to the right in a tail recursive way.

## Filtering lists

To filter a list we give it a predicate function to create a new list that contains only objects that return true on the predicate. A function that takes another function is so common in functional programming (as you have seen from the previous `map`, `foldLeft` and `foldRight` operations) that there is a special name for it, it's a `higher order function`. A function that takes another function and/or produces a function as it's result is said to be `higher order` (yeah, being higher order isn't some absurdly complicated concept).

Let's look at how we would like it to look:

{% highlight scala %}
"filter a list" in {
  val original = LinkedList(1, 2, 3, 4, 5)
  original.filter(x => (x % 2) == 0) === LinkedList(2, 4)
}
{% endhighlight %}

So you have a list, call `filter` on it sending in a function to say what kind of object you want at your filtered list. In this case, we want all even numbers and at the end we get `LinkedList(2,4)`. Let's look at the implementation now:

{% highlight scala %}
def filter( f : (E) => Boolean ) : LinkedList[E] = {
  foldRight(LinkedList[E]()) {
    (item, acc) =>
      if ( f(item) ) {
        Node(item, acc)
      } else {
        acc
      }
  }
}
{% endhighlight %}

Look, `foldRight` again!

Now, why didn't we do this with a `foldLeft` in the first place? It's much more efficient than a `foldRight`.

The main reason for this is maintaing order. If we used a `foldLeft` here we would have `LinkedList(4,2)` as a result and this would change the order the objects were presented on our list and this would be an undesirable side effect. By using a `foldRight` we now have exactly the output we want, which is the items filtered at the same order they were found in the list.

And our function itself doesn't do much, it checks if the current item matches the predicate function `f`, if it does, includes it at the head of the accumulator list, otherwise returns the accumulator itself. Again, we're just composing stuff and nothing more.

## Rebuilding map

And since we now have a `foldRight` let's reimplement our `map` method to use that instead of manually doing the looping, here's how it would look like:

{% highlight scala %}
def map[R](f: E => R): LinkedList[R] = foldRight(LinkedList[R]()) {
  (item, acc) =>
    Node(f(item), acc)
}
{% endhighlight %}

Simple, isn't it?

Again, we use a `foldRight` here because we need to maintain the order of the elements, we can't return a reversed result list to users of this method.

## Calculating the size of a list

To calculate the size of a linked list you usually need to traverse the whole list counting how many nodes it has, since you don't know how many nodes were added to it. You could hide this behind a list type that would hide the way the nodes are built and increment the size whenever a new item is added, but since our `LinkedList` implementation is immutable we can do better, we can just have the size calculated automatically for us in a single operation.

First, we declare a property size at the `LinkedList` trait:

{% highlight scala %}
sealed trait LinkedList[+E] {
  def size : Int 
  // ... other methods implemented here
}
{% endhighlight %}

And we include implementations at the `Node` class:

{% highlight scala %}
case class Node[+E](head: E, tail: LinkedList[E]) extends LinkedList[E] {
  val size = 1 + tail.size
}
{% endhighlight %}

And in at `Empty` as well:

{% highlight scala %}
case object Empty extends LinkedList[Nothing] {
  val size = 0
}
{% endhighlight %}

Since you can't add items at the end of a `LinkedList` objects, the size of a list is known at the time it is created, it's always `1 + tail size` and given the tail has already been completely initialised, it has this value already calculated and you can just get it, so, calculating the size of our list is s simple operation.

Now, as you have noticed, I used `def` to declare the method at the `LinkedList` trait but at the classes I have used `val`. Why is that? Declaring `val`'s in traits is usually frowned upon, you use a trait to include more operations, not to hold state, so while we declare it as a `def` at the parent trait, our classes define it as `val`s and for Scala it doesn't matter, a method that doesn't take any arguments can safely be replaced by a `val` anywhere and callers of the code don't have to know anything about this. Also, if it was a `def` at `Node` and `Empty` then our implementation would not be optimised at all and would still traverse the whole list. Since we made it a `val` at both ends it is initialised when the object is created and never changed again.

## Cons operator (::)

If you hanged around functional code before you probably saw colons around code, both as `::` or as `:::`, in functional programming these are known as the `cons` operator (this name comes from [LISP](http://en.wikipedia.org/wiki/Cons) but ML and Scala refer to it as cons as well). We use this to build lists and it's special because it's right associative in Scala. Since it's right associative, we can build lists like this:

{% highlight scala %}
"build lists with cons" in {
  LinkedList(1, 2, 3, 4) == 1 :: 2 :: 3 :: 4 :: Empty
}
{% endhighlight %}

This code, if calling the `::` directly instead of like an operator would be:

{% highlight scala %}
"build lists with cons manually" in {
  LinkedList(1, 2, 3, 4) == Empty.::(4).::(3).::(2).::(1)
}
{% endhighlight %}

In Scala, any operator that ends with `:` (colon) becomes right associative. This way, when you build a list using it, it looks like the final result, given the list is built backwards (starting from the tail) but we traverse it forward. Let's look at how the method is implemented:

{% highlight scala %}
  def ::[B >: E](element : B) : LinkedList[B] = Node(element, this)
{% endhighlight %}

Not much there to be said, we could just call this method `add`, it's `::` mostly to make use of the right associativity to look nicer and to pay homage to the ML language that influenced Scala syntax and style so much. The generic declaration `[B >: E]` is there to make the `Empty` case possible given when you do `Empty.::(1)` you are effectively building a new list of `Int` out of a `LinkedList[Nothing]` and you need to say it's valid to create a new list of type `B` given `B` is a super type of `E` as `E` in this case is `Nothing`, the subtype of all types. So `[B >: E]` means that `B` is any super type of `E`.

The other well known case is the `:::` operator that includes a list in front of the other, here's how we use it:

{% highlight scala %}
"appending two lists" in {
  val current = LinkedList(1, 2, 3, 4)
  val other = LinkedList(10, 11, 12, 13)

  ( other ::: current ) === LinkedList(10, 11, 12, 13, 1, 2, 3, 4)
}
{% endhighlight %}    

Just like `::` this one is also right associative, so it's the same as doing `current.:::(other)`, we use the right associativity here mostly to show that `other` will be prefixed to `current`.

The implementation includes something new for us:

{% highlight scala %}
def :::[B >: E](prefix : LinkedList[B]) : LinkedList[B] = {

  @tailrec def helper(acc : LinkedList[B], other : LinkedList[B]) : LinkedList[B] = {
    other match {
      case Node(head,tail) => helper(head :: acc, tail)
      case Empty => acc
    }
  }

  helper(this, prefix.reverse())
}
{% endhighlight %}

Given we can't make `:::` tail recursive per se, what we do here is yet another common idiom you will find in functional languages, an internal helper method. Now the `helper` method can easily be made tail recursive so we use this to optimize our implementation. 

There isn't anything special about internal helper methods,  it's just like any other method, but it's only visible here inside our method and not outside of it, given no one really needs to know it exists and it's only useful in this specific case, that's the perfect place for it to be.

## Looping through the elements of a list

And while we covered most pieces of how you can build new stuff out of lists, we didn't look at how we can simply loop through a list. If you have a list and all you want to do is loop through the elements without producing a new value or a new list, you're probably looking at a **side effect**.

This isn't inherently bad or evil in any way, it's just that, different from pure functions, a function that causes a side effect depends on context or information that's out of the function itself and this usually makes them harder to test and understand that they are doing. Still, side effects are the main way our programs interact with external systems, so there's no hiding from them, you will eventually need to write code that causes side effects and this is fine, just keep in mind the downsides of it while doing it.

In Scala collections, the method to loop through elements is `foreach`, here's how it could be implemented:

{% highlight scala %}
def foreach(f : (E) => Unit) {
  @tailrec def loop( items : LinkedList[E] ) {
    items match {
      case Node(head,tail) => {
        f(head)
        loop(tail)
      }
      case Empty => {}
    }
  }

  loop(this)
}
{% endhighlight %}

It takes a function as a parameter and calls the function with each element contained in the list itself. Again, we use a helper method here to do the magic and be tail recursive, we could have implemented it with `foreach` itself being tail recursive but this just looks a bit cooler (yeah, I do like ML a lot).

And since we're all about side effects now, our test needs to cause side effects as well, let's look at it:

{% highlight scala %}
"foreach implementation" in {
  val items = new ListBuffer[Int]()

  LinkedList(1, 2, 3, 4).foreach( (x) => items += x )

  items === List(1, 2, 3, 4)
}
{% endhighlight %}

And here we are accessing a variable out of the loop and mutating it to be able to test our implementation, not ideal, but that's what we wanted in any case.

## Wrapping up

Now we know more about the trade offs we have made when we decided to build our `LinkedList` object as immutable, we optimised it to be tail recursive everywhere, included a couple new operations like `filter`, `foldRight`, `foreach` and know we know that any operator that ends in `:` (colon) is right associative.

At the next part, we'll dig deeper into how lists interact with other functional concepts in the language.