---
layout: post
title: Learning Scala by building Scala - Lists
---

While trying to come up with a compelling reason to get back at blogging I thought about all I've been learning over these last few months and it's all about functional programming. Coursera courses, books, learning new languages, it all boils down to learning how you can build programs the functional way, so, why not put a bit of all this into a couple blog posts and, better yet, use Scala for it?

After doing a bunch of [Standard ML](http://www.smlnj.org/) and [Racket](http://racket-lang.org/) for [Dan Grossman's Programming Languages course](https://www.coursera.org/course/proglang), it's sad to see that most of the mainstream languages are still so far away in terms of features and functionalities when compared to something as ancient as ML (from the early 70's!). It's great to see the resurgence of these ideas in languages like Scala and Clojure and if you haven't jumped the bandwagon yet, it's time for you to do it :)

# Setup
To follow this tutorial you will need [SBT](http://www.scala-sbt.org/) and I'd recommend you to use an IDE, but you can definitely use SBT to compile and run the project if you'd prefer to use a basic text editor. You can check a list of IDE's and plugins available at [Typesafe's website](http://typesafe.com/platform/tools/scala).

Now reate a file at the `PROJECT_ROOT/build.sbt` path with the following contents (assume **PROJECT_ROOT** is the folder you created to follow this tutorial):

{% highlight scala %}
name := "list-tutorial"

version := "1.0"

scalaVersion := "2.10.3"

libraryDependencies ++= Seq(
    "org.specs2" %% "specs2" % "2.3.4" % "test"
  )
{% endhighlight %}

This is our basic project configuration, we will only have `Specs2` as a dependency for this tutorial. If you're using Eclipse or IntelliJ, you should now create the `PROJECT_ROOT/project/plugins.sbt` file with the following content:

{% highlight scala %}
addSbtPlugin("com.github.mpeltonen" % "sbt-idea" % "1.5.2")

addSbtPlugin("com.typesafe.sbteclipse" % "sbteclipse-plugin" % "2.4.0")
{% endhighlight %}

This includes plugins to generate project files for both IDEs. If you're using Eclipse, just type `sbt eclipse` and import the project, if you're on IntelliJ, just use `sbt gen-idea` and import the project. If you're not using any of them, use `sbt build` and `sbt test` to compile and run tests for your project.

## Lists, camera, action!
Lists are one of the basic constructs of functional programming and it couldn't be different in Scala. Let's start by defining our LinkedList object:

{% highlight scala %}
sealed trait LinkedList[+E]

case class Node[+E]( val head : E, val tail : LinkedList[E]  ) extends LinkedList[E]

case object Empty extends LinkedList[Nothing]
{% endhighlight %}

Now we have a bunch of concepts here, first, there's the `sealed trait`. Traits, in Scala, are a mix of Java interfaces and Ruby modules. You can define a collection of methods you expect people to implement for your trait and you can also have base implementations available at your trait so that clients won't have to implement them all.

In this specific case, I'm using a `trait` because I don't want people to be able to create `LinkedList` objects directly. This could also be done by using an abstract class, but traits are just simpler. 

Now, what about `sealed`? The `LinkedList` object is not **open for extension**, we don't want people to create their own derivations of it. By making it `sealed` we let the compiler know that only classes inside the same file as the declaration of `LinkedList` can inherit/implement it. Now the only two possible subclasses for `LinkedList` are `Node[+E]` and `Empty`. 

As for the `[+E]`, it's the type parameter for the `LinkedList` type so we can make sure we hold only one kind of object there. If you haven't seen type parameters or generics yet, don't worry, this won't be super important for what we're doing here.

Moving on, now we have `Node[+E]`. First, what's a `case class`? A case class is a class that allows you easily pattern match on it using it's constructor. You could manually do it, but by defining it as a case class you can forget about all that and just use all the pattern matching magic we will see below.

And while I'm talking about constructors, can you spot the constructor for the `Node[E]` class? Look again:

{% highlight scala %}
( val head : E, val tail : LinkedList[E]  )
{% endhighlight %}

This is the constructor for the `Node[+E]` class. In Scala, the constructor is part of the class declaration itself. We say this is the primary constructor, all other constructors you define for this class will have to call this primary constructor in some way, so you are forced to have a single point of entry for creating your class and this is a good thing, you would usually have to do the same manually if you were in a language like Java or C# and this best practice was translated to a language requirement.

Since linked lists are a recursive structure at heart, our `Node[+E]` definition reflects just that, you have a `head` field that is an object of type `E` and a tail that is just another `LinkedList[+E]` object. Just like you would have implemented a linked list in any other language.

What about this `val` thing?

`val` means this value is **immutable**. In Scala and in functional programming in general, you will see that there is a lot of value in keeping stuff immutable. It's much simpler to reason about code when you don't have to care if the values are changing or not, specially if you're writing multi-threaded or concurrent code. So, whenever possible, make use of `val` to declare your variables (yeah, bad name here).

When declaring case classes, all fields are assumed to be `val`s, so I'm using it here just so you know this is the default. You can just remove it and they will still be immutable.

And if you're used to C-like languages the way the type is declared for the variable might feel weird, first you say the name of the variable (`head` in this case) and then you do `: E` to declare it's type. 

Why is it like that?

Because Scala has local type inference, when you declare a variable inside a method or object body you can do it like this:

{% highlight scala %}
val number = 1
{% endhighlight %}

Given the right hand side, Scala already knows you have a number there, so you don't have to type the variable type, but you could if you wanted to:

{% highlight scala %}
val number : Int = 1
{% endhighlight %}

So declaring the type after the variable makes more sense than doing it before when you have type inference.

The `extends` just lets us know that we are extending/implementing the `LinkedList[E]` trait.

Now on to the trickiest part of this all, `Empty`. `Empty` is not a class, it's a singleton object (we do not use `class` in it's declaration). In Scala, we don't have static methods or variables, everything has to be at an instance of something and `Empty` is the value we will use to implement our list terminator. It would be equivalent of using a global variable or `null` to signal the end of a list, but without the drawbacks of these options. Imagine you use `null` as the terminator for a list, what would you do if the user wanted to insert `null` on it? Yeah, it's tricky. With this singleton object we wouldn't have this kind of problem.

As you can see, it doesn't hold any values and it's type parameter is `Nothing`. In Scala, `Nothing` is the bottom type of all types. It's meant to be used in these special cases of generics when you want to signal the lack of a value but still be type safe and it works because the compiler assumes `Nothing` is the subtype for all types. That's also why our class' type parameter is defined as `[+E]` and not `[E]` only, we accept objects of type `E` and it's subclasses (so we can accept `Nothing`, the subclass of everything).

But don't worry too much about it, generics won't affect us much here.

## Operation time
Now that we have our data structure defined, let's implement some operations we would like to see in our list. 

### Creating lists of items

First, let's have something to help us create new lists in a simple way, let's allow the user to create a new list object by calling `LinkedList(1, 2, 3, 4)`. Here's how you would do it:

{% highlight scala %}
object LinkedList {

  def apply[E]( items : E* ) : LinkedList[E] = {
    if (items.isEmpty) {
      Empty
    } else {
      Node( items.head, apply(items.tail : _*) )
    }
  }

}
{% endhighlight %}

In Scala, when you do `something()`, you're actually calling the `apply()` method. It's just syntax sugar around the call. And as we have seen before, since Scala doesn't have static methods, we declare a singleton object called `LinkedList` (given there is a trait named `LinkedList`, we say this is the companion object for `LinkedList`) and now we can declare any methods that would not make sense at `LinkedList` instances here.

In Scala, to declare the type a method returns, we use the syntax `: Type =` which is exactly the same we would use for an assignment. We could remove the `: Type` here given the compiler can infer the type of the expression, but I personally like to have method return types defined so it's easier for someone else to look at them and see what they return.

Since `Node` is a case class we could either call the constructor `new Node(head,tail)` or we can use the shortcut the case class include that is an `apply` method that takes the same parameters as the constructor, like we are doing at this example.

The implementation itself is quite simple, we have the parameter `items : E*`, which is a `vararg` (the `*` denotes it's a sequence of `E`s) and we use it to recursively build the list. The `: _*` is required for us to tell the compiler we are not sending in a sequence of `E` as the first parameter but the sequence is all the parameters (it's equivalent to the * operator in Ruby).

### Mapping one list into another

What is the goal of the `map` method? To transform a data structure by applying a definite operation on every element of the structure and returning a new structure with the result. So, if we had the following list `(2,3,4)` and the map operation is squaring an item then it would produce the list `(4,9,16)`.

Let's start by writing our fist specification for the behaviour we want to see (this class will be created under `src/scala/test`):

{% highlight scala %}
import org.specs2.mutable.Specification

class LinkedListSpecification extends Specification {

  "linked list" should {

    "map correctly" in {
      val original = LinkedList(2, 3, 4)
      original.map(x => x * x) === LinkedList(4, 9, 16)
    }

  }

}
{% endhighlight %}

In `Specs2` parlance the `===` operator is equivalent to JUnit's `Assert.assertEqual` or RSpec's `should == `. If the items are not equal it would raise an exception. You can find a full list of matchers for `Specs` [here](http://etorreborre.github.io/specs2/guide/org.specs2.guide.Matchers.html#Matchers).

This is the usage we expect to have, on any `LinkedList` object we should be able to give it an operation and this operation will be applied to all items and we will get back a new list with the produced objects. One upside we have for free since we made `Node` and `Empty` case classes is that they already have an `==` implementation that compares their internal properties, so as along as our lists contain objects that correct implement the `==` operator we don't have to care much about implementing it or the `hashCode` method.

Now, let's see how we could implement the `map` method:

{% highlight scala %}
sealed trait LinkedList[+E] {

  def map[R]( f : E => R ) : LinkedList[R] = {
    this match {
      case Node(head, tail) => Node(f(head), tail.map(f))
      case Empty => Empty
    }
  }

}
{% endhighlight %}

`map` takes a single parameter, a function `f` with type `E => R`. This means it's a function that takes an item of type `E` (the type we hold at this list) and turns it into some type `R`. The `=>` signals to Scala that we are taking a function here. And the return type is a `LinkedList[R]` since our function turns each `E` item into an `R` item.

At our implementation we see our first case of pattern matching in Scala, using the `match` keyword. We are matching on the this, the list itself, and if it's a `Node` we build a new node by applying `f` at the head and then mapping again on the tail. If it's `Empty` we just return the `Empty` list since we don't have more items to apply `f`.

The `case Node(head, tail)` is possible because the `Node` class is a case class that has already implemented the pattern matching logic for us on it's constructor so the pattern matcher implementation will bind the constructor fields to the variables we declare there. They didn't have to be called `head, tail`, I could just call them `x` and `xs` and it would have the same effect. What's important here is that we don't need to manually switch or check both cases, the `match/case` construct and our case class will do it all for us.

If we wanted to implement this without pattern matching we could also have done it with subclassing:

{% highlight scala %}
sealed trait LinkedList[+E] {
  def map[R]( f : E => R ) : LinkedList[R]
}

case class Node[+E]( val head : E, val tail : LinkedList[E]  ) extends LinkedList[E] {
  override def map[R]( f : E => R ) : LinkedList[R] = Node(f(head), tail.map(f))
}

case object Empty extends LinkedList[Nothing] {
  override def map[R]( f : Nothing => R ) : LinkedList[R] = this
}
{% endhighlight %}

It would, mostly, have the same effect, but you'd have to implement the method at both places. Given we already know all subclasses we will have for our `LinkedList` we will just use pattern matching for all examples here.

Another important thing on this second possible solution is that we did not wrap our method implementations around `{}`, at `Node` we just have `Node(f(head), tail.map(f))` and that's it. Scala does not require you to use `{}` to wrap around a method body as long as each expression evaluates to something that returns the expected value. So, if you're sick of angle brackets, you can just remove them if the expressions you are using allow you to.

Almost all examples you see here could have their `{}` removed from the method declarations. Try removing them later and decide what you think is better for your reading.

### Folding over data

Imagine you want to sum all numbers in a list of numbers, here's how you could do it:

{% highlight scala %}
def sum( numbers : LinkedList[Int] ) : Int = {
  numbers match {
    case Node(head, tail) => head + sum(tail)
    case Empty => 0
  }
}
{% endhighlight %}

Simple, isn't it? Now what if you wanted to do the same with a list of strings?

{% highlight scala %}
def join( numbers : LinkedList[String] ) : String = {
  numbers match {
    case Node(head, tail) => head + join(tail)
    case Empty => ""
  }
}
{% endhighlight %}

Can you see the pattern here? We have a neutral value and we take the current item and joint it with the recursive call with the tail of our list. These are classic examples of a `fold` operation.

Fold is usually defined as a binary operator you apply to an accumulator and to a value in your collection, producing a new accumulator for the next operation. Basically, it's a way to abstract the algorithm above so you can use it with any type. Let's look at how we could define a `foldLeft` method at our `LinkedList` trait:

{% highlight scala %}
sealed trait LinkedList [+E] {

  // map implementation above here

  @tailrec final def foldLeft[B]( accumulator : B )( f : (B,E) => B ) : B = {
    this match {
      case Node(head, tail) => {
        val current = f(accumulator, head)
        tail.foldLeft(current)(f)
      }
      case Empty => accumulator
    }
  }
  
}
{% endhighlight %}

We have a bunch of new stuff here. Let's start with this `@tailrec` annotation. The JVM doesn't implement the **tail call optimization** natively, which means recursive functions like the `map` above or this `foldLeft` could cause stack overflow errors for large collections, since each recursive call allocates a new stack element and there is a limit on how deep the stack can get. 

So, instead of giving up on recursion completely, if your method is **tail-recursive** (it calls itself at the end of one of it's branches) you can annotate it with `@tailrec` and the Scala compiler will optimize it to a loop for you. Whenever you're building a recursive function, try to make it **tail-recursive** so you can let the compiler optimize it for you. One requirement of applying the **tail call optimization** is that the function itself has to be marked final (and this is yet another reason we need to declare our methods at `LikedList` and not at it's subclasses).

Now, getting to the method, instead of just calling it fold, we call it `foldLeft` because we fold to the left. If we manually applied the calls of summing the list `LinkedList(1, 2, 3)` they would be `f(f(f(0, 1), 2), 3)` so we apply the function form the left to the right. Why is it important? Because you could have built a foldRight that applies from right to left and some operations could yield a different result if you're coming form the right (like merging strings or a division).

Now let's get to the list of parameters:

{% highlight scala %}
( accumulator : B )( f : (B,E) => B )
{% endhighlight %}

We have two separate lists of parameters here, the first contains the initial value and the second contains the function we will use to fold over the data. Having separate lists of parameters allows us to **curry** methods calls, that is applying a function with only part of the parameters producing a new function that takes the missing parameters. 

I'll go deeper into this concept in future posts, this is visible here mostly because this is the same signature that you will see at the default Scala collections and it would probably be weird if I had one signature here and when you started to use real Scala lists you saw a different one.

As for the implementation itself, there isn't much here. It's a common recursive function where we compute the next accumulator and send it forward with a recursive call. If we have reached the end of the list, just return the current accumulator itself.

Let's see how our spec for it would look:

{% highlight scala %}
"foldLeft summing all numbers" in {
  val original = LinkedList(2, 3, 4)
  original.foldLeft(0)((acc,item) => acc + item) === 9
}

"foldLeft making a single string from all numbers" in {
  val original = LinkedList(2, 3, 4)
  original.foldLeft(new StringBuilder())((acc,item) => acc.append(item) ).toString() === "234"
}

"map and foldLeft to sum the squares" in {
  val original = LinkedList(2, 3, 4)
  original.map(x => x * x).foldLeft(0)((acc, x) => acc + x) === 29
}
{% endhighlight %}

As you can see, we can reuse the `foldLeft` operation for whenever we need to build one object out of the other. We could even implement the `map` function above in terms of a fold!

The other important piece here is that we need to give the parameters in separate just like we declare them separately. So it's `foldLeft`, the accumulator or neutral object and then the function we are going to apply.

## More next time

And we have covered lists, map and foldLeft here, all very important constructs when doing functional programming and working with Scala in general. Next we will move on to a couple other methods on lists and more functional programming constructs. Stay tuned!

### References
If you'd like to dig deeper into all this, check out these resources:

* [Programming Languages course by Dan Grossman on Coursera](https://www.coursera.org/course/proglang)
* [Functional Programming Principles in Scala course by Martin Odersky](https://www.coursera.org/course/progfun)
* [Functional Programming in Scala book by Paul Chiusiano and Rúnar Bjarnson](http://www.manning.com/bjarnason/)