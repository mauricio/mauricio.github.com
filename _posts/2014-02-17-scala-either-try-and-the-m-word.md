---
layout: post
title: Scala's Either, Try and the M word
tags:
- useful
---

Since we have covered [Option]({% post_url 2013-12-25-learning-scala-by-building-scala-lists-part-3 %}) previously, it's time to show you other types just like `Option` that are prevalent in Scala's standard library and third party code. We will also see how these types are part of a larger set of objects and they have this name that starts with **M** that, unfortunately, shuts people off when they hear about it so I won't type it here just yet.

## `Either[T]` one thing or the other

If you look at `Either`'s Scala Docs you will see it says it is a disjoint union. In math, a disjoint union is a collection of two sets that have no items in common, when we translate this to Scala, imagine that each set is a different type and the items are instances of these two types.

Saying we return an `Either[String,Int]` means that we could return an `Int` or a `String`, they're both different types and don't share much. In fact, we usually use them for completely different things, so why would we ever care about using something like this?

One of the most common cases is because we use exceptions when we shouldn't. If you wrote Objective-C code somewhere in this or in a past life, you have probably seen [NSError](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/Classes/NSError_Class/Reference/Reference.html) objects lying around in your codebase. If you have never seen Objective-C, don't despair, `NSError` is an object that's used throughout Objective-C APIs to give you better information about errors that have happened while you have tried to do something.

`NSError` is not an exception object, you don't throw, raise, catch or rescue `NSError` objects (Objective-C has it's own [NSException](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/Classes/NSException_Class/Reference/Reference.html) class for that), they're not meant for that. They're meant to convey more information about why your code failed to do whatever you wanted it to do.

And why is it not an exception, you ask?

Because exceptions are for exceptional cases, for when something is really broken, `NSError` is used when the **other case** is not an exceptional case but something that happens with some frequency and that you should handle it gracefully. The main goal here is to make it clear from the types you use that a method could have two different outcomes and they are common enough that you should care about them both and make sure your code is capable of handling them.

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

The pattern is mostly what we have seen before, you have the base `sealed trait` and then you have case classes we can use to pattern match on the values. We also have a `fold` method that can be used to produce an output to the computation for both cases, mostly a shortcut to pattern matching.

Let's look at an example of using it:

{% highlight scala %}
case class User( id : Int, name : String, password : String )

case class ServiceResponse( status : Int, message : String )

class ServiceClient( val users : Map[Int,User]) {

  def userDetails(id : Int, password : String) : Either[ServiceResponse,User] = {

    users.get(id) match {
      case scala.Some(user) => if ( user.password == password ) {
        Right(user)
      } else {
        Left(ServiceResponse(401, "You can not view this user's details"))
      }
      case scala.None => Left(ServiceResponse(404, "User does not exist"))
    }

  }

}
{% endhighlight %}

Here we have a simple `ServiceClient` class that could be an HTTP client talking to some external service. This external service could respond with specific error codes depending on what the client is asking and how he is asking. These error codes don't need to be exceptions, that's just how HTTP works, we could have a success and receive the user data or get one of the non-success HTTP response codes with a message and that's this message that makes either useful here.

If we were just looking at "user" and "no user" scenarios, we could easily model this interaction using `Option`, but if we did that we would lose the ability to show the detailed message produced by the server
to the client of our app. He would just see that "there's no user", without knowing what is actually going on.

Let's fold on the data now:

{% highlight scala %}
class EitherSpecification extends Specification {

  val service = new ServiceClient(
    Map(1 -> User(1, "John Doe", "123456"))
  )

  "either" should {

    "fold to 401" in {

      val message = service.userDetails(1, "none").fold(
        (response) => {
        s"Password does not match ${response.status} - ${response.message}"
      }, (user) => {
        s"User is ${user.name}"
      } )

      message === "Password does not match 401 - You can not view this user's details"
    }

    "fold to 404" in {

      val message = service.userDetails(50, "none").fold(
        (response) => {
          s"User does not exist ${response.status} - ${response.message}"
        }, (user) => {
          s"User is ${user.name}"
        } )

      message === "User does not exist 404 - User does not exist"
    }

    "return the user details" in {

      val message = service.userDetails(1, "123456").fold(
        (response) => {
          "should not have come here"
        }, (user) => {
          s"User is ${user.name}"
        } )

      message === "User is John Doe"
    }

  }

}
{% endhighlight %}

As you can see, folding on `Either` is specially nice if you have to build some output message based on the objects being returned. This could be a command line app, a webapp or anywhere where you had to render some message in all cases.

So, whenever you have a method that could possibly return two different types, `Either` will be there for you.

## Using `Try[T]` to compose on exceptions

Previously, `Either` was also used to handle the exception case, you call a method that could possibly raise an exception, you would use `Either`, with `Left` being the error and `Right` the expected value. Since Scala 2.10, this usage was replaced by the use of `Try`. A `Try` wraps a computation that could either result in a value or in an exception being thrown. Think about it as a specialization for `Either`, while you would use `Either` whenever you have to return one thing or the other, with `Try` it's always one thing or an error.

Being specific like this, means that using `Try` for the error case is much simpler than doing the same with `Either`. Let's look at how we could implement it:

{% highlight scala %}
object Try {
  def apply[T](f: => T): Try[T] =
    try {
      Success(f)
    } catch {
      case NonFatal(e) => Failure(e)
    }
}

sealed trait Try[+T] {

  def flatMap[U](f: (T) => Try[U]): Try[U]
  def map[U](f: (T) => U): Try[U]
  def foreach[U](f: T => U): Unit
  def isSuccess: Boolean
  def isFailure: Boolean
  def getOrElse(f: => T): T = f

}

case class Success[+T](value: T) extends Try[T] {

  override def flatMap[U](f: T => Try[U]): Try[U] =
    try {
      f(value)
    } catch {
      case NonFatal(e) => Failure(e)
    }

  override def map[U](f: T => U): Try[U] = Try[U](f(value))
  override def foreach[U](f: T => U): Unit = f(value)
  override def getOrElse(f: () => T): T = value
  override def isSuccess = true
  override def isFailure = false

}

case class Failure[T <: Nothing](exception: Throwable) extends Try[T] {

  override def flatMap[U](f: (T) => Try[U]): Try[U] = this
  override def map[U](f: (T) => U): Try[U] = this
  override def foreach[U](f: T => U): Unit = {}
  override def isSuccess = false
  override def isFailure = true

}
{% endhighlight %}

And again we have that same pattern, one sealed trait and two case classes. Just like `Option[T]`, the main advantage of using `Try[T]` is being able to compose with the value without caring about what's inside. It's just like the Schrodinger's cat story, you keep working with the box and delay opening it up until it's completely necessary to know what's happening in there.

And how do we do that? We `map` and `flatMap` with the computation. It doesn't matter if it's a `Success` or a `Failure`, when we use `map` and `flatMap` we compose on the value and wait for it to be something. Let's look a bit at the usage of `Try[T]`:

{% highlight scala %}
"be a failure when it can't parse the number" in {
  val result = Try( "abc".toInt )
  result.isFailure must beTrue
}

"be a success when it parses the number" in {
  val result = Try( "10".toInt )
  result.isSuccess must beTrue
  result match {
    case Success(v) => v === 10
    case Failure(e) => throw new IllegalStateException("should not have come here")
  }
}
{% endhighlight %}

Using `Try[T]` is a bit different from using `Either` or `Option` because you can just wrap a computation around it instead of creating a `Success` or a `Failure` manually. Given we know some computation can fail, we can just use the `Try[T].apply` method at the companion object and it will automatically wrap the correct value or the error and return a `Try[T]` for us.

While when we write `Try( "abc".toInt )` it looks like we are running `"abc".toInt` before sending it in as a parameter, in reality, the Scala compiler knows that we are expecting a `=> U` function and automatically wraps that code into a closure. This is called [thunking](http://en.wikipedia.org/wiki/Thunk_(functional_programming)) or a lazy parameter, since it is not evaluated before being given to the method. In Scala lingo, you will also see people calling this a **pass by name**, since, instead of sending it the computed value, you are sending in a **named function** that will, in turn, produce the computed value.

The `NonFatal` reference at the `try/catch` block is to mean that we want to catch any exception that is actually recoverable. Some errors (like JVM errors) are not really safe to be caught so we just use this `NonFatal` here at `Try[T]` to make sure we don't try to catch them as well and catch only exceptions that we can recover.

And while this is good and all, you can also manually build a try from `Success` or `Failure` as well if you would like to. If you are working with concurrent systems, where you're handling `Future[T]` and `Promise[T]` you will most likely make heavy use of `Try[T]` results for your computations.

Let's do some composing:

{% highlight scala %}
"be composable with map" in {
  val result = Try("4".toInt).map( v => v * v ).map( v => v / 2 )

  result match {
    case Success(v) => v === 8
    case Failure(e) => throw new IllegalStateException("should not have come here")
  }
}

"be composable with flatMap/for comprehensions" in {

  val result = for (
    v <- Try("5".toInt);
    k <- Try("6".toInt);
    z <- Try("9".toInt)
  ) yield( v + k + z)

  result match {
    case Success(r) => r === 20
    case Failure(e) => throw new IllegalStateException("should not have come here")
  }
}

"fail mapping when one of the tries is a failure" in {
  val result = Try("abc".toInt).map( v => v * v)
  result.isFailure must beTrue
}

"fail flatMap when one of the tries is a failure" in {
  val result = for (
    v <- Try("5".toInt);
    k <- Try("JOE".toInt);
    z <- Try("9".toInt)
  ) yield( v + k + z)

  result.isFailure must beTrue
}
{% endhighlight %}

And since we have `map` and `flatMap` implemented, we can both manually map the calls and also use for comprehensions (`flatMap`) on our results.

And other than making it possible for you to wrap a computation that could possibly fail, the most important feature of using `Try[T]` is that the exception information is stored to whoever needs to unwrap the value at the end of the chain. You don't have to do the error prone `catch(Exception e) throw new SomeOtherException(e)` all the way up to the code that actually needs the value (or the error), you just use a `Try[T]` at all the intermediate steps of the computation and the top level code that will grab the value can look at the real error (and not some infinite chain of bogus exceptions) and behave accordingly.

## And what about the `M` word?

Well, if you came this far, you have seen the pattern already. Let's look at what it looks like:

{% highlight scala %}
trait Monad[+T] {

  def flatMap[U]( f : (T) => Monad[U] ) : Monad[U]
  def unit(value : B) : Monad[B]

}
{% endhighlight %}

And there it is. Monads are containers for values and the container must have a `flatMap` (you can also find this being called `bind`) and a `unit(v)` operation. 

The type declarations are enough for us to figure out what these two methods mean, `flatMap` means transforming a value that is inside a monad into another value still inside the same type of monad. Why is it necessary to keep ir wrapped? Think about Schrodinger's cat again, we want to delay the decision of knowing what's inside the box as much as possible so that I can do something like:

{% highlight scala %}
  val result = for (
    v <- Try("5".toInt);
    k <- Try("6".toInt);
    z <- Try("9".toInt)
  ) yield( v + k + z)
{% endhighlight %}

The same would be true if we were dealing with `Option[T]`. When composing many options, we might have a `None` somewhere but we don't want to care about that until it is necessary to look inside the box.

Now that we know that `flatMap` means for a monad, what is this `unit(v)`? Well, it's what you use to wrap a value. It's the `Some(v)`, the `Success(r)` and even the `List(v)` (yes, list is a monad as well). In Scala, all monads will have `flatMap` implemented directly, but each one will have it's own version of `unit(v)`. Usually, it's going to be some constructor or `apply` method at a companion object. Still, they will have have these two operations.

And what about `map`? Aren't we using `map` everywhere?

Well, `map` is just a special case for `flatMap`, here's how we could write `map` for `Option[T]`:

{% highlight scala %}
  def map[R](f : E => R) : Option[R] = flatMap(v => Some(f(v)))
{% endhighlight %}

In our `Monad[T]` implementation this would look like:

{% highlight scala %}
  def map[U](f : (T) => U) : Monad[U] = flatMap(v => unit(f(v)))
{% endhighlight %}

Exactly the same code. So we don't actually need `map` but having it defined as well is a nice shortcut for some common patterns as well.

To define something to be a monad, you use the 3 monad laws, the first is associativity:

{% highlight scala %}
monad.flatMap(f).flatMap(g) == monad.flatMap(v => f(v).flatMap(g)) // associativity
{% endhighlight %}

Using `Option[T]`, we could have this as:

{% highlight scala %}
"be associative" in {
  val multiplier : Int => Option[Int] = v => Some(v * v)
  val divider : Int => Option[Int] = v => Some(v/2)
  val original = Some(10)

  original.flatMap(multiplier).flatMap(divider) ===
    original.flatMap(v => multiplier(v).flatMap(divider))
}
{% endhighlight %}

So, it doesn't matter if you do the `flatMap` inside another `flatMap` or if you do it at the result produced. It has to produce exactly the same values.

The second is the left unit law, here's the definition:

{% highlight scala %}
unit(x).flatMap(f) == f(x)
{% endhighlight %}

Which would become the following for `Option[T]`:

{% highlight scala %}
"be left unit" in {
  val multiplier : Int => Option[Int] = v => Some(v * v)
  val item = Some(10).flatMap(multiplier)

  item === multiplier(10)
}
{% endhighlight %}

So, getting a monad and running `flatMap` on it with some function is the same as calling the some function with the wrapped `x` value.

And the third law is the right unit law, let's look at the definition:

{% highlight scala %}
monad.flatMap(unit) == monad
{% endhighlight %}

Which in turn would be defined as follows for `Option[T]`:   

{% highlight scala %}
"be right unit" in {
  val value = Some(50).flatMap(v => Some(v))
  value === Some(50)
}
{% endhighlight %}

And for this last one, we mean that having a monad, running `flatMap` on unit, we should have the same as `unit(x)`.

To validate these laws, you can't just go through these unit tests, you would have to replace all function calls with the actual code (which we won't do here) and check that the expressions generated are compatible (as you would do in a mathematical equation), but if you can guarantee that your container object respects these 3 laws then you have a monad in place.

As you can see, there isn't anything specially complicated about monads, they're just a container type that follows a collection of rules (which are very important, the right unit rule, for instance, allows us to use monads in for-comprehensions) and are used as container types.

As an aside, there is some debate as to if `Try[U]` is a full monad or not. The problem is that if you think `unit(x)` is `Success(x)`, then exceptions would be raised when you try to execute the **left unit** law since `flatMap` will correctly wrap an exception but the `f(x)` might not be able to do it. Still, if you assume that the correct unit is `Try.apply` then this would not be an issue. In any case, while `Try` might not be a pure monad, it's close enough so you can use it much the same way.

Didn't see the other posts about this? Check the two ones about `List`:

* [Part 1]({% post_url 2013-11-25-learning-scala-by-building-scala-lists %})
* [Part 2]({% post_url 2013-12-08-learning-scala-by-building-scala-lists-part-2 %})

For more about monads and Scala, check these ones:

* Monads are elephants by James Iry - [Part 1](http://james-iry.blogspot.com.br/2007/09/monads-are-elephants-part-1.html) - [Part 2](http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-2.html) - [Part 3](http://james-iry.blogspot.com.br/2007/10/monads-are-elephants-part-3.html) - [Part 4](http://james-iry.blogspot.com.br/2007/11/monads-are-elephants-part-4.html)
* [Reactive programming course](https://www.coursera.org/course/reactive)
* [Functional Programming in Scala](http://www.manning.com/bjarnason/)