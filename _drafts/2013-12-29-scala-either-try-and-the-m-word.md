---
layout: post
title: Scala's Either, Try and the M word
---

Since we have covered [Option]({% post_url 2013-12-25-learning-scala-by-building-scala-lists-part-3 %}) previously, it's time to show you other types just like `Option` that are prevalent in Scala's standard library and third party code. We will also see how these types are part of a larger set of objects and they have this name that starts with **M** that, unfortunately, shuts people off when they hear about it so I won't type it here just yet.

## Either one thing or the other

If you look at `Either`'s Scala Docs you will see it says it is a disjoint union. In math, a disjoint union is a collection of two sets that have no items in common, when we translate this to Scala, imagine that each set is a different type and the items are instances of these two types.

Saying we return an `Either[String,Int]` means that we could return an `Int` or a `String`, they're both different types and don't share much. In fact, we usually use them for completely different things, so why would we ever care about using something like this?

One of the most common cases is because we use exceptions when we shouldn't. If you wrote Objective-C code somewhere in this or in a past life, you have probably seen [NSError](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/Classes/NSError_Class/Reference/Reference.html) objects lying around in your codebase. If you have never seen Objective-C, don't despair, `NSError` is an object that's used throughout Objective-C APIs to give you better information about errors that have happened while you have tried to do something.

`NSError` is not an exception object, you don't throw, raise, catch or rescue `NSError` objects (Objective-C has it's own [NSException](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/Classes/NSException_Class/Reference/Reference.html) class for that), they're not meant for that. They're meant to convey more information about why your code failed to do whatever you wanted it to do.

And why is it not an exception, you ask?

Because exceptions are for exceptional cases, for when something is really broken, `NSError` is used when the **other case** is not an exceptional case but something that happens with some frequency and that you should handle gracefully. The main goal here is to make it clear from the types you use that a method could have two different outcomes and they are common enough that you should care about them both and make sure your code is capable of handling them.

Let's get to the code now:

{% highlight scala %}
sealed trait Either[+L,+R] {

  def isLeft : Boolean
  def isRight : Boolean

  def fold[X](leftFunction : (L) => X, rightFunction : (R) => X) : X =
    this match {
      case Right(value) => rightFunction(value)
      case Left(value) => leftFunction(value)
    }

}

case class Right[R](value : R) extends Either[Nothing,R] {
  override def isLeft = false
  override def isRight = true
}

case class Left[L](value : L) extends Either[L,Nothing] {
  override def isLeft = true
  override def isRight = false
}
{% endhighlight %}

The pattern is mostly what we have seen before, you have the base `sealed trait` and then you have case classes we can use to pattern match on the values. We also have a `fold` method that can be used to produce an output to the computation for both cases, mostly a shortcut to pattern matching. Let's see how we can use that:

{% highlight scala %}
{% endhighlight %}