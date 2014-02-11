---
layout: post
title: Learning Scala by building Scala - Lists and Option
tags:
- scala
- useful
---

And off we go to build a couple more list operations and understand new concepts and styles of working with collections and values in Scala. If you didn't see the fist two parts of of this tutorial, check them below before moving forward:

* [Part 1]({% post_url 2013-11-25-learning-scala-by-building-scala-lists %})
* [Part 2]({% post_url 2013-12-08-learning-scala-by-building-scala-lists-part-2 %})

## Finding an item in a list given a predicate

At **part 2** we saw how we could filter a list given a predicate function, but what if I wanted to find and get an item given a predicate?

Imagine I have a list of `Person` instances and I'd like to find someone with the **Josh** first name. I could use `filter` for this and grab the first item in the list, but that would be awkward. How are people usually doing it?

Let's see how this would look like in Ruby:

{% highlight ruby %}
found = people.find { |p| p.first_name == 'Josh' }
puts "#{found.first_name} #{found.last_name}"
{% endhighlight %}

As you can see, just like we had a filter method at our `LinkedList`, the find method for enumerables in Ruby accept a predicate function and will return the first item for which the block returns true.

But, what if the block never returns true for any of the objects?

Well, then you would get `nil` (the `null` in Ruby). 

But what if you wanted to find the nil inside an enumerable?

{% highlight ruby %}
items = [1, nil, 2]
found = items.find { |p| p == nil }
puts found
{% endhighlight %}

For this case, the find method accepts a parameter to signal the lack of a value, so we could write the code like this: 

{% highlight ruby %}
items = [1, nil, 2]
found = items.find(0) { |p| p == nil }
if found == 0
  puts "There are no nils"
else
  puts "There is a nil"
end
{% endhighlight %}

This special value carries no meaning on itself, it's just a magical value we decided to use so we could carry on building our code, but it's an error prone solution and would have to be documented somewhere **out** of the code so someone calling our code understands what is happening and we know this is a bad sign.

You can see these **special** values in many places, if you know Java you know the `indexOf` method in `String` returns `-1` if the string given is not included anywhere and, again, you need to read the docs to know that this is the case and handle it correctly.

Can we do better? Of course we can! 

### Option comes to the rescue

Our problem is that we need to find a way to say that something has two states, it either has a value or it doesn't. This idea is prevalent in functional programming in general and the solution is the `Option` (ML, Scala)  or `Maybe` (Haskell) type. This type encapsulates the idea of having or not having a value. Let's see how we can implement it in Scala:

{% highlight scala %}
sealed trait Option[+E]

case class Some[+E]( element : E ) extends Option[E]
case object None extends Option[Nothing]
{% endhighlight %}

Looks a bit like our `LinkedList` declaration, doesn't it?

This is almost like declaring a marker type so you can know that what is being returned could either be a value or be nothing and that's exactly what this is for, to **taint** your code in a way that you can't ignore that not having a value is a possibility, it's **encoded right into the types**, you don't have to read the docs to know this, it's already there in your code to be seen.

Now let's see how our find method could be implemented:

{% highlight scala %}
@tailrec final def find( p : (E) => Boolean  ) : Option[E] = {
  this match {
    case Node( head, tail ) => {
      if ( p(head) ) {
        Some(head)
      } else {
        tail.find(p)
      }
    }
    case Empty => None
  }
}
{% endhighlight %}

The implementation is extremely simple, check if the head of the current node matches the predicate, if it matches, return a `Some(head)`, if it doesn't call find on the tail. If we have reached the end of the list, return `None`. Let's see how we can use this in real code:

{% highlight scala %}
"find John" in {
  val items = LinkedList("John", "Josh", "Mary")
  items.find( name => name == "John" ) === Some("John")
}

"not find John" in {
  val items = LinkedList("Josh", "Mary")
  items.find( name => name == "John" ) === None
}

"find with pattern matching" in {
  val items = LinkedList("Josh", "Mary")
  items.find( name => name == "Mary" ) match {
    case Some(item) => success
    case None => failure("Should not have come here")
  }
}
{% endhighlight %}

And other than the last case, when we pattern match, doesn't look like this is super cool, does it?

## Option as a one item collection

Well, it isn't. The coolness of `Option` comes when we think about it as a collection that can hold at most one value and compose on this idea. Let's add a couple methods to it.

{% highlight scala %}
sealed trait Option[+E] {
  def isDefined : Boolean

  def map[R](f : (E) => R) : Option[R]
  def flatMap[R]( f : E => Option[R] ) : Option[R] = if ( isDefined ) f(this.get) else None
  def foreach[U]( f : (E) => U )
  def get() : E
  def getOrElse[B >: E]( f : => B ) : B = if ( isDefined ) get() else f
}

case class Some[+E]( element : E ) extends Option[E] {
  override val isDefined = true
  override def map[R](f : (E) => R) : Option[R] = Some(f(element))
  override def foreach[U]( f : (E) => U ) = f(element)
  override def get() : E = element
}

case object None extends Option[Nothing] {
  override val isDefined = false
  override def map[R](f : (Nothing) => R) : Option[R] = None
  override def foreach[U]( f : (Nothing) => U ) = {}
  override def get() : Nothing = throw new NoSuchElementException("There is no object here, this is a None")
}
{% endhighlight %}

Now we clearly have some useful code around here, let's look at how we could use all this:

{% highlight scala %}
"option" should {

  "be something" in {
    val item = Some("10")
    item.get() === "10"
  }

  "be mapped to some value in a for comprehension" in  {
    val upper = for ( name <- Some("Joe") ) yield name.toUpperCase
    upper.get() === "JOE"
  }

  "be mapped to some value manually" in {
    val number = Some("10").map(n => n.toInt)
    number.get() === 10
  }

  "it can't be anything if it is a none" in {
    val something : Option[Int] = None
    val result = something.map( x => x * 5)
    result.isDefined must beFalse
  }

}
{% endhighlight %}

The main takeaway here is that by thinking about `Option` as a collection with at most one element, we can compose on it as if it is any collection, but with some special knowledge.

At the beginning of the `Option` declaration we have the `isDefined` method that tells us if this option is a `Some` or a `None`, it's mostly a shortcut to pattern matching. Once we go on, we get to the meat of our implementation, the `map` method. This is what allows us to compose with the option and ignore if it's something or empty until we really have to care about it.

This means we can either go for the no-sugar version that calls map directly:

{% highlight scala %}
val number = Some("10").map(n => n.toInt)
number.get() === 10
{% endhighlight %}

Or we can use the sugarized version with for-comprehensions:

{% highlight scala %}
val upper = for ( name <- Some("Joe") ) yield name.toUpperCase
upper.get() === "JOE"
{% endhighlight %}

Both have the same effect, but if you have to handle many options, the for comprehension would looks nicer:

{% highlight scala %}
"find the numbers with for comprehension" in {
  val numbers = LinkedList(1, 2, 3, 4, 5)

  val result = for {one <- numbers.find(x => x == 1)
                    two <- numbers.find(x => x == 2)
                    moreThan4 <- numbers.find(x => x > 4)
  } yield one + two + moreThan4

  result.get() === 8
}
{% endhighlight %}

This comprehension means **I want to add the 1, the 2 and the first number that's bigger than 4** and only that. If any of these numbers aren't there, give me a none. Think about it a bit, without `Option`, you would have a collection of nested if statements there, but with `Option` you don't have to care about that anymore. If any of the `find` calls returns `None` the whole operation becomes a `None` and all other operations will not happen anymore.

Without for-comprehensions the code is a bit uglier:

{% highlight scala %}
"find the numbers flatMapping" in {
  val numbers = LinkedList(1, 2, 3, 4, 5)

  val result = numbers.find(x => x == 1)
    .flatMap(one =>
    numbers.find(x => x == 2)
      .flatMap(
      two => numbers.find(x => x > 4).map(
        moreThan4 =>
          one + two + moreThan4)))

  result.get() === 8
}
{% endhighlight %}

Not as good as the original, is it?

There's also something else here, `flatMap`. Why is it here? Because we need to `flatten` our options, otherwise the result of running this operation would be `Option[Option[Option[Int]]]` and that's not what we want and to fix this we use `flatMap` that **flattens** or `unwraps` our `Option[Option[Int]]` to an `Option[Int]`. Again, using the for-comprehension prevents us from having to write these transformations manually, but `map` and `flatMap` are both required if you want to use them, the for-comprehension itself is just a simpler way to write the code above.

And as I mentioned above, if any of the parts becomes `None`, it all becomes `None`:

{% highlight scala %}
"wont find anything" in {
  val numbers = LinkedList(1, 2, 3, 4, 5)

  val result = for {one <- numbers.find(x => x == 1)
                    two <- numbers.find(x => x == 2)
                    moreThan4 <- numbers.find(x => x > 5)
  } yield one + two + moreThan4

  result === None
}
{% endhighlight %}

It doesn't matter if it's something or empty, just map on it and keep composing on the options you get back until, eventually, you have to grab a value out of the option. In most cases, you can and should defer the decision to take a value out until there's no way to send an option and, in this case, you probably want to use `getOrElse` instead of `get`. `get`, as you can see from `None`'s implementation, isn't safe and will cause side effects it not handled correctly, so avoid doing it unless it's really necessary or you don't care about the possibility of raising an exception.

## getOrElse and lazyness

And while we're at `getOrElse`, the idea behind it is as simple as it's implementation. If you really need to have a value out of something that could be empty, you definitely **need** a default value, by using the `getOrElse` you can now have this default available directly here instead of waiting somewhere else to be used and you can also make sure that it will be **only** at the place where it is necessary, and not scattered everywhere in your codebase.

Also, look at the way we have defined `getOrElse`:

{% highlight scala %}
def getOrElse[B >: E]( f : => B ) : B = if ( isDefined ) get() else f
{% endhighlight %}

The **or else** value isn't a value per se, it's a **function**. Why is that? Because we want to be lazy, but in a good way. Think about it, if the option is a `Some` this value will never be used, does it make sense to create this value in all cases? No, it doesn't, so, instead of making `getOrElse` take a value, it takes a function that returns a value. Here's how it looks when we use it:

{% highlight scala %}
"be getOrElse the string" in {
  val item = Some("10")
  item.getOrElse("25") === "10"
}
{% endhighlight %}

Well, it doesn't looks like I'm calling a function, does it? It's because the Scala compiler is smart enough to understand that even thought I did type just a string, what I mean is that I want a function that returns a string and it will generate just that. So it looks like that string is being created every time, but it isn't, it will only be created when the option is a `None` so we don't incur in the object creation penalty every time we use `getOrElse`.

## And there is more

And let's not forget `foreach` that is, again, mostly for side effects. If you don't care about composing an option and all you want is to run some code if there is something in there, just use `foreach` and be happy with it. If there is something, your block of code will be called, if there isn't, nothing will happen.

So, after all that, here are some of the advantages of using `Option` in your codebase:

* You don't have to document the fact that calling a method could return something or not. When you say it returns `Option[Something]` whoever is calling it knows it already and will have to handle it carefully. You have baked type safety inside this operation.
* You can simplify your conditionals by building your code upon composing options instead infinitely nested operations, this makes for code that's easier to read and to reason about.
* If you are always composing on options and don't need **special** values, like **null**, you can forget null handling! Yes, by using `Option`, your code should be able to live and run without caring about the existence of `null`. If you walk around Scala's standard library and most third party libraries you will see that whenever something would be handled by returning something or `null`, it will return `Option`, so this idiom is pervasive in the ecosystem and you should use it as much as possible as well.

## Code as the documentation

The real beauty here is that we have encoded something that was usually just some documentation lying around into real code that can be compiled and tested. Now, whenever you see `Option` being used in Scala, you know what it means and how you are supposed to use it in your code, there's no need to check the documentation to figure out "what happens if nothing is found" since you already know `None` happens.

There are a bunch of other objects like `Option` at the Scala standard library, like `Either` and `Try` and we will cover them in the future, for now, enjoy and use `Option` a lot.