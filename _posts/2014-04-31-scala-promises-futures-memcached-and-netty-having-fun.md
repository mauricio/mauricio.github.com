---
layout: post
title: Scala, promises, futures, Netty and Memcached get together to have monads
subtitle: who doesn't like to mix a lot of stuff like this?
keywords: scala, promises, futures, netty, async, memcached
tags:
- scala
- useful
---

Monad all the things!

Continuing our collection of articles about building and using common Scala features, it's time to talk about the much hyped `Futures` and `Promises`. If you look around any community that has embraced async programming (like the JavaScript community) you will see people going crazy about promises. They are, actually, a very simple concept and what most other people will call a `Promise` is a `Future` in Scala (and in Java as well). But let's get started on this, right?

If you haven't seen the other pieces of this collection of articles, you might want to check them out:

* [Part 1 - Lists - creating, mapping and folding]({% post_url 2013-11-25-learning-scala-by-building-scala-lists %})
* [Part 2 - Lists - folding right, filtering, consing and looping]({% post_url 2013-12-08-learning-scala-by-building-scala-lists-part-2 %})
* [Part 3 - Lists and Options]({% post_url 2013-12-25-learning-scala-by-building-scala-lists-part-3 %})
* [Part 4 - Either, Try and Monads]({% post_url 2014-02-17-scala-either-try-and-the-m-word %})

And as usual, the source code for this [is at GitHub](https://github.com/mauricio/list-tutorial).

## I `Promise[T]` you a good (or bad, I don't know yet) `Future[T]`

As I said before, what people call `promises` out there are the `futures` for us in Scala. Here's what a `Promise[T]` is:

> Promise is an object which can be completed with a value or failed with an exception.

So what we have to build here is something that can be completed with a success or exception. Can you think of something we have that's exactly that? Oh yeah, it's a `Try[T]`. So, a `Promise[T]` will be something akin to a `Try[T]`, we'll see where it becomes different in a minute.

Let's look at our first stab at implementing a `Promise[T]`:

{% highlight scala %}
package async

import scala.util.{Failure, Success, Try}

object Promise {
  def apply[T]() = new Promise[T]()
}

class Promise[T] {

  @volatile private var result : Try[T] = null

  def isCompleted : Boolean = result != null

  def value : Try[T] = {
    if (this.isCompleted) {
      result
    } else {
      throw new IllegalStateException("this promise is not completed yet")
    }
  }

  def complete(result : Try[T]) : this.type = {
    if ( !this.tryComplete(result) ) {
      throw new IllegalStateException("promise already completed")
    }

    this
  }

  def tryComplete( result : Try[T] ) : Boolean = {
    if ( result == null ) {
      throw new IllegalArgumentException("result can't be null")
    }

    synchronized {
      if ( isCompleted ) {
        false
      } else {
        this.result = result
        true
      }
    }
  }

  def success( value : T ) : this.type = complete(Success(value))
  def trySuccess( value : T ) : Boolean = tryComplete(Success(value))

  def failure(exception : Throwable) : this.type = complete(Failure(exception))
  def tryFailure(exception : Throwable) : Boolean = tryComplete(Failure(exception))

}

{% endhighlight %}

The implementation is rather simple, a single instance variable (marked as `volatile` since we will possibly have many threads checking it) and the `tryComplete` method where all the action happens. When you have an actual value to complete the promise, you call `tryComplete` or any of the other utility methods and they will complete the promise if possible.

The _completing_ logic is quite simple. If it isn't `null`, set the value and return `true` signaling that this is the first time someone has tried to complete this promise. Otherwise, return false and don't do anything. The whole action is wrapped in a synchronized block to make sure many threads trying to complete the same promise won't leave the promise itself in a bad state.

The other methods are mostly there as validations or shortcuts to our implementation, as is the `complete` method that can't be called twice. You might be wondering what the `this.type` return types mean, well, they mean what you're thinking already, if you subclass this `Promise[T]` whenever there is a `this.type` the type will be your subclassed type and not `Promise[T]` alone. So you could have your own special promise and it's type would be visible for callers of these methods as well.

The `value` method isn't actually part of the actual Scala's `Promise[T]` implementation, it's there just to simplify our tests at this moment. Here's how they are looking so far:

{% highlight scala %}
package async

import org.specs2.mutable.Specification
import scala.util.{Failure, Try}

class PromiseSpecification extends Specification {

  "promise" should {

    "complete with a value" in {
      val promise = Promise[String]()
      promise.complete(Try("some-value"))
      promise.isCompleted must beTrue
      promise.value.get === "some-value"
    }

    "complete with an error" in {
      val promise = Promise[String]()
      promise.complete(Failure(new Exception()))
      promise.isCompleted must beTrue
      promise.value.isFailure must beTrue
    }

    "tryComplete called many times does not complete twice" in {
      val promise = Promise[String]()
      promise.tryComplete(Try("some-value")) must beTrue
      promise.tryComplete(Try("some-other-value")) must beFalse
      promise.isCompleted must beTrue
      promise.value.get === "some-value"
    }

    "raise an error if completed more than once" in {
      val promise = Promise[String]()
      promise.complete(Try("some-value"))
      promise.complete(Try("some-other-value")) must throwA[IllegalStateException]
    }

    "should not accept null as a value" in {
      val promise = Promise[String]()
      promise.complete(null) must throwA[IllegalArgumentException]
    }

  }

}
{% endhighlight %}

Not much to see here so far, we have a simple implementation and a bunch of simple tests. Where's the magic?

## Preparing for the `Future[T]`

Well, as I said before, what people out there call `promise` for us it will be `Future[T]`. Our promise object produces a `Future[T]` object that can be given to other people to work on it's _future_ result. When you think about it, a `Promise[T]` is something you use internally to produce a `Future[T]`, clients of your code won't ever see the promise, all they will see is the `Future[T]` that is managed by this promise. In short, `futures` are where all the fun happens in our async code.

Here's our `Future[T]`:

{% highlight scala %}
trait Future[T] {

  def isCompleted: Boolean

  def value: Option[Try[T]]

  def flatMap[S](f: (T) => Future[S])(implicit executor: ExecutionContext): Future[S]
  def map[S](f: (T) => S)(implicit executor: ExecutionContext): Future[S]

  def foreach[U](f: (T) => U)(implicit executor: ExecutionContext): Unit = map(f)

  def onComplete[U](f: (Try[T]) => U)(implicit executor: ExecutionContext): Unit

  def onFailure[U](pf: PartialFunction[Throwable, U])(implicit executor: ExecutionContext) = onComplete {
    case Failure(e) => pf.apply(e)
    case _ =>
  }


  def onSuccess[U](pf: PartialFunction[T, U])(implicit executor: ExecutionContext): Unit = onComplete {
    case Success(v) => pf.apply(v)
    case _ =>
  }

}
{% endhighlight %}

Yes, it's a trait!

We don't want people knowing what the actual future looks like, since we might have many implementations for it, so all interactions will be with __something that implements `Future[T]`__. 

Looking at the methods, the first 3 are our old friends, `flatMap`, `map` and `foreach`. But there's something different here, they also take an `ExecutionContext` as a parameter. What is that? 

Since we're working on asynchronous code, we don't actually know when our code will be executed. Different from the usual collection where the `flatMap` would happen right away, here it will happen sometime in the future when this future is actually completed. The `ExecutionContext` here serves as a way for us to tell where the `flatMap` will be executed, this is important because the original code that signals this future to complete itself shouldn't care if this operation is fast or takes forever, so it must provide it's own execution context (as if it was a thread pool) to execute itself.

Also, the `ExecutionContext` parameter is given as a separate parameter list:

{% highlight scala %}
(implicit executor: ExecutionContext)
{% endhighlight %}

Why is that?

Because we want to allow clients of our code to simplify the way they interact with promises. Scala allows you to declare many parameter list declarations so you can `curry` your functions, call a function with less parameters than it actually takes and producing a function that takes only the missing parameters. In this case, we're not interested in currying the function, but in taking the `ExecutionContext` from the implicit scope. The implicit scope is a special scope in Scala where you can put variables that will be filled in by the compiler instead of yourself. 

This will simplify our interactions with `Future[T]` objects because we will be able to declare a single `ExecutionContext` in the implicit scope and the compiler will pick it and set it for all calls of these methods. For us, it will be as if this parameter doesn't even exist, but we could send in a different value if we wanted.

The `onComplete` is the most important method here, since it is the one that takes your code and runs it on all cases, both success or failure. All other methods revolve around using `onComplete` to do their jobs. We could even fully implement this trait here and leave only `onComplete`, `value` and `isCompleted` as an abstract methods, but we'll leave the implementation to our concrete `future` below.

`onFailure` and `onSuccess` are mostly simplifications for our code if we don't care about an specific outcome, they just do the pattern matching for us so we can give the code a partial function.

Other than that, we have `isCompleted` and `value` that will let us now when the future has been completed and what value it holds.

Now let's get to implementing our `DefaultFuture[T]`:

{% highlight scala %}
package async

import scala.util.{Failure, Success, Try}
import scala.concurrent.ExecutionContext
import scala.collection.mutable.ArrayBuffer
import scala.util.control.NonFatal

class DefaultFuture[T] extends Future[T] {

  class FutureCallback( val function : (Try[T]) => Any, val context : ExecutionContext )

  @volatile private var result : Try[T] = null
  private val callbacks = new ArrayBuffer[FutureCallback]()

  def isCompleted: Boolean = result != null

  def value: Option[Try[T]] = if (this.isCompleted) {
    Some(result)
  } else {
    None
  }

  def complete(value : Try[T]) {
    if (value == null) {
      throw new IllegalArgumentException("A future can't be completed with null")
    }

    synchronized {
      if ( !this.isCompleted ) {
        result = value
        fireCallbacks()
      }
    }
  }

  override def onComplete[U](f: (Try[T]) => U)(implicit executor: ExecutionContext): Unit = {
    val callback = new FutureCallback(f, executor)
    this.synchronized {
      if ( this.isCompleted ) {
        fireCallback(callback)
      } else {
        callbacks += callback
      }
    }
  }

  private def fireCallbacks() {
    callbacks.foreach(fireCallback)
    callbacks.clear()
  }

  private def fireCallback( callback : FutureCallback) {
    callback.context.execute(new Runnable {
      def run() = callback.function(result)
    })
  }

  def flatMap[S](f: (T) => Future[S])(implicit executor: ExecutionContext): Future[S] = {
    val p = Promise[S]()
    onComplete {
      case Success(v) => try {
        f(v).onComplete(p.complete)
      } catch {
        case NonFatal(e) => p.failure(e)
      }
      case Failure(e) => p.failure(e)
    }
    p.future
  }

  def map[S](f: (T) => S)(implicit executor: ExecutionContext): Future[S] = {
    val p = Promise[S]()
    onComplete { v => p complete (v map f) }
    p.future
  }  

}
{% endhighlight %}

Wow, now that's a lot of code!

Our `DefaultFuture[T]` implementation starts with two variables, the result (as with `Promise[T]`) and the callbacks collection. This collection keeps all objects that are sent to `onComplete`, mapping each function received with it's `ExecutionContext`. This is important because each callback could use it's own execution context and we have to make sure we are executing the callbacks at the correct context.

Now we get to `isCompleted` and `value`, there isn't much to see here, the method return types and implementations are simple enough for us to understand what's going on.

The magic starts at `complete`. Here we have the code that completes this future with a value, as with `Promise[T]`, the future has to be completed with a `Try[T]` object and it won't take null as a value. Everything happens inside a synchronized block because we must make sure no changes happen to the callbacks collection before we are able to fire events and clear it. 

The `fireCallbacks` method will execute each callback in it's own execution context and then clear the callbacks collection. Clearing the collection in this case is necessary because we could end up with a cycle of futures and promises pointing to each other and causing GC woes, so we just clear them all as soon as we can. And we have a separate `fireCallback` method because it will be reused at our `onComplete` as well.

Going down a bit we arrive at `onComplete`, the main entry point for clients of our `Future[T]` object. The implementation is dead simple, we create a future callback object, enter a synchronized block (to make sure we don't conflict with `complete`) and if we're not completed yet, we add the callback to our collection of callbacks, if we are completed, we execute the callback right away.

Now, can you see any complications about this? No? It's because there aren't. The idea is simple and straightforward, the actual implementation at Scala's standard library is more complicated because they have to make sure it works in all cases and use as little resources as possible, but the core idea is what we have here, a simple object that can be completed and that will fire events once something arrives.

What about `flatMap` and `map`?

Oh, they're cool as well but they're cheating. As you can see, they create a promise and return that promise's future to callers. What they actually do is that they register a callback on the current future and they will execute their given operation once the current future completes. We can see there is a really strong relationship between futures and promises here.

While `map` is self explanatory, `flatMap` is a bit different. Why is that? Because the function we take for `flatMap` has to return a future so we need to evaluate the function, grab the future and then add a callback on it for when it ends. Since we don't have the `Try[T]` protection as we have in `map` when we do `(v map f)` we also have to handle the case where the function given fails to produce a `Future[T]` and raises an exception, we have to forward that exception to the future we returned to callers of our code (just as we did on `Try[T]` on part 4).

Our `Promise[T]` object has also changed a bit, let's see where it did change:

{% highlight scala %}
class Promise[T] {
	// other implementations

  private val internalFuture = new DefaultFuture[T]()
  def future : Future[T] = internalFuture

  def tryComplete( result : Try[T] ) : Boolean = {
    if ( result == null ) {
      throw new IllegalArgumentException("result can't be null")
    }

    synchronized {
      if ( isCompleted ) {
        false
      } else {
        this.result = result
        this.internalFuture.complete(result) // firing the future callbacks
        true
      }
    }
  }

}
{% endhighlight %}

We have included a `DefaultFuture` object to our promises so they can give this to clients and we have also changed the `tryComplete` method to also complete the `future` and fire it's callbacks when a promise is completed. Now the code we saw at `DefaultFuture` is definitely correct.

And how do we use it? Well, let's look at the specs:

{% highlight scala %}
package async

import org.specs2.mutable.Specification
import scala.collection.mutable.ArrayBuffer
import scala.util.{Failure, Success}

class DefaultFutureSpecification extends Specification {

  implicit val executionContext = CurrentThreadExecutionContext

  "default future" should {

    "correctly execute the callbacks once completed" in {
      val future = new DefaultFuture[String]()
      val items = new ArrayBuffer[String]()

      future.onSuccess { case value => items += value }
      future.complete(Success("some-value"))

      items === List("some-value")
      future.isCompleted must beTrue
    }

    "correctly execute the callback right away after completion" in {
      val future = new DefaultFuture[String]()
      val items = new ArrayBuffer[String]()

      future.complete(Success("some-value"))
      future.onSuccess { case value => items += value }

      items === List("some-value")
    }

    "correctly execute the many callbacks registered" in {
      val future = new DefaultFuture[String]()
      val items = new ArrayBuffer[String]()

      future.onSuccess { case value => items += value }
      future.onSuccess { case value => items += value }
      future.onSuccess { case value => items += value }
      future.complete(Success("some-value"))

      items === List("some-value", "some-value", "some-value")
    }

    "map the value into something else" in {
      val future = new DefaultFuture[String]()

      val mapped = future.map(s => s.toInt)

      future.complete(Success("1"))

      mapped.value.get.get === 1
    }

    "flatMap the future into another future" in {
      val future = new DefaultFuture[String]()
      val otherFuture = new DefaultFuture[String]()

      val result = for ( first <- future;
                         second <- otherFuture )
                      yield first.toInt + second.toInt

      future.complete(Success("5"))
      otherFuture.complete(Success("3"))

      result.value.get.get === 8
    }

    "should fail callbacks correctly" in {
      val future = new DefaultFuture[String]()
      val exception = new Exception()
      var caughtException : Throwable = null

      future.onFailure { case f =>
        caughtException = f
      }

      future.complete(Failure(exception))

      caughtException === exception
    }

    "should fail right away if failed already" in {
      val future = new DefaultFuture[String]()
      val exception = new Exception()
      var caughtException : Throwable = null

      future.complete(Failure(exception))

      future.onFailure { case f =>
        caughtException = f
      }

      caughtException === exception
    }

    "should return none when not completed" in {
      val future = new DefaultFuture[String]()
      future.value === None
    }

  }

}
{% endhighlight %}

As you can see from the spec, we __never__ send in the `ExecutionContext` parameter we declared in all these methods. As we said above, the compiler will search this parameter in the implicit context for this class before asking me for a value and I have set the value there with this line:

{% highlight scala %}
implicit val executionContext = CurrentThreadExecutionContext
{% endhighlight %}

This sets an execution context to the implicit context and the compiler happily uses this value all over the place whenever it encounters a method call that requires an execution context with the `implicit` keyword.

And our execution context implementation is dead simple as well:

{% highlight scala %}
package async

import scala.concurrent.ExecutionContext

object CurrentThreadExecutionContext extends ExecutionContext {

  def execute(runnable: Runnable): Unit = runnable.run()
  def reportFailure(t: Throwable): Unit = t.printStackTrace()

}
{% endhighlight %}

Just execute whatever you take at the current thread. Not perfect, but simplifies our testing a lot since actually testing async calls would make the tests much more brittle.

## Netty comes to the show

Building futures and promises and using them like we did is ok, but if really want to understand how to use them we have to use them in a real async situation and that's where [Netty](http://netty.io/) and [Memcached](http://memcached.org/) arrive to help us, we will build a dead simple `Memcached` client with `Netty` and see how we can use promises and futures to build our APIs.

Let's look at the operations we want to have declaring a trait for our client:

{% highlight scala %}
trait Client {

  def set(key: String, bytes: Array[Byte], flags: Int = 0, expiration: Int = 0): Future[StatusResponse]
  def get(key: String): Future[GetResponse]
  def delete(key: String) : Future[StatusResponse]
  def connect(): Future[Client]
  def close(): Future[Client]

}
{% endhighlight %}

These are the basic operations we need, `connect`, `disconnect`, `set`, `get` and `delete`. You could easily build all other operations from the codebase we'll build, but for this example these are enough. The interesting fact about all this is that none of these methods return an actual value, they all return `Future[T]` objects because this client is async, it won't block until the `memcached` server has produced a value so we can't tell you there is a value but that __there will be__ a value at some point in the future.

Before we dig into the actual networking code, we have to define what our messages will look like. Our client won't really know much about the binary protocol used to communicate to `memcached`, all this will be hidden inside our encoders and decoders, all it will know are the high level messages we will encode and decode to/from the binary protocol. 

First, we have a couple constants:

{% highlight scala %}
package memcached.netty.messages

object Keys {
  // magic
  val RequestKey = 0x80
  val ResponseKey = 0x81

  // requests

  final val Get = 0x00
  final val Set = 0x01
  final val Delete = 0x04
}
{% endhighlight %}

These are just a bunch of constants we use when building messages with `memcached`, the first two are used as markers so network inspection tools can know if it's a client sending a message to the server or the server sending a response to a client. The other three constants are used to identify which command was sent to the server.

Now let's look at the messages client can send to servers:

{% highlight scala %}
package memcached.netty.messages

sealed abstract class ClientRequest( val code : Int )

class SetRequest( val key : String, val value : Array[Byte], val flags : Int = 0, val expiration : Int = 0 )
  extends ClientRequest(Keys.Set)

class GetRequest( val key : String )
  extends ClientRequest(Keys.Get)

class DeleteRequest( val key : String )
  extends ClientRequest(Keys.Delete)
{% endhighlight %}

For every method we have on our client, there's a message we can use. This is also true for how the binary protocol itself is modeled. Ideally, you would have a class for every __message__ your protocol defines.

Now let's look at the possible server responses:

{% highlight scala %}
package memcached.netty.messages

object ServerResponse {
  final val Ok = 0x0000
  final val NotFound = 0x0001
  final val Exists = 0x0002
  final val ItemNotStored = 0x0005

  final val ValueTooLarge = 0x0003
  final val InvalidArguments = 0x0004
  final val IncrementDecrementNonNumeric = 0x0006
  final val Unknown = 0x0081
  final val OutOfMemory = 0x0082
}

sealed abstract class ServerResponse(
  val command: Int,
  val status: Int,
  val opaque: Int,
  val cas: Long) {

  import ServerResponse._

  def isError: Boolean = status match {
    case Ok | NotFound | Exists | ItemNotStored => false
    case _ => true
  }

}

class StatusResponse(command: Int, status: Int, opaque: Int, cas: Long, val body: Option[String] = None)
  extends ServerResponse(command, status, opaque, cas)

class GetResponse(val value: Option[Array[Byte]], status: Int, val flags: Int, opaque: Int, cas: Long)
  extends ServerResponse(Keys.Get, status, opaque, cas)
{% endhighlight %}

In the case of server responses, we have a bit less diversity. We start with a collection of constants, symbolizing the possible status codes we could receive from `memcached`. The `ServerResponse` the fields we will always have when we get a `memcached` response, status, command, CAS and opaque. These fields are part of all responses you will receive from the server. 

Here we also define what's going to be an error for us. It might be weird to think that anything other than `Ok` are not errors, but `NotFound`, `Exists` and `ItemNotStored` are all expected responses when you're talking to `memcached` and clients should handle them, these are not exceptional cases, they are all natural and will happen when you're talking to the server. On the other hand, status like `ValueTooLarge` are not expected and will cause the client to throw an exception, clients should correctly abide by memcached requirements when sending messages to it.

Moving on, we have two subclasses for our `ServerResponse` object. `StatusResponse` is the __catch all__ case. Most of the time the only response you will get from `memcached` is a status code about how the operation was executed (or not executed), this is, by far, the most common response we will see. 

The other subclass is `GetResponse`, which is what we receive when we execute a `GET` request on `memcached`. This one is different because we have the value that is possibly stored there and we also have flags, opaque and CAS fields that are part of this response.

## Encoding messages

So far, so good, we have the client requests and the server responses modeled, now it's time to start writing Netty code. Let's start with the request encoder:

{% highlight scala %}
package memcached.netty

import io.netty.handler.codec.MessageToByteEncoder
import io.netty.channel.ChannelHandlerContext
import io.netty.buffer.ByteBuf
import memcached.netty.messages._
import scala.annotation.switch
import io.netty.util.CharsetUtil
import memcached.netty.messages.SetRequest
import memcached.netty.messages.GetRequest

class MemcachedEncoder extends MessageToByteEncoder[ClientRequest] {

  def encode(ctx: ChannelHandlerContext, msg: ClientRequest, out: ByteBuf) {
    (msg.code: @switch) match {
      case Keys.Set => encodeSet(out, msg.asInstanceOf[SetRequest])
      case Keys.Get => encodeGet(out, msg.asInstanceOf[GetRequest])
      case Keys.Delete => encodeDelete(out, msg.asInstanceOf[DeleteRequest])
      case _ => throw new UnknownRequestException(msg)
    }
  }

  def encodeSet(buffer : ByteBuf, set: SetRequest) {
    val key = set.key.getBytes(CharsetUtil.US_ASCII)
    buffer
      .writeByte(Keys.RequestKey)
      .writeByte(Keys.Set)
      .writeShort(key.size)
      .writeByte(8) // extras length
      .writeByte(0) // data type
      .writeShort(0) // reserved
      .writeInt(key.size + 8 + set.value.size) // total body size
      .writeInt(0) // opaque
      .writeLong(0) // CAS
      .writeInt(set.flags)
      .writeInt(set.expiration)
      .writeBytes(key)
      .writeBytes(set.value)
  }

  def encodeGet(buffer : ByteBuf, get: GetRequest) {
    encodeKeyMessage(buffer, get.key, Keys.Get)
  }

  def encodeDelete(buffer : ByteBuf, delete: DeleteRequest) {
    encodeKeyMessage(buffer, delete.key, Keys.Delete)
  }

  def encodeKeyMessage( buffer : ByteBuf, keyName : String, code : Int ) {
    val key = keyName.getBytes(CharsetUtil.US_ASCII)
    buffer
      .writeByte(Keys.RequestKey)
      .writeByte(code) // message code
      .writeShort(key.size) // key size
      .writeByte(0) // extras length
      .writeByte(0) // data type
      .writeShort(0) // reserved
      .writeInt(key.size) // total body size
      .writeInt(0) // opaque
      .writeLong(0) // CAS
      .writeBytes(key)
  }

}
{% endhighlight %}

And here we are finally digging into Netty. The encoder's goal is to turn one of our high level `ClientRequest` messages into a `ByteBuf` (a collection of bytes) which is what actually gets written to the wire. This class doesn't know anything about our client or how we're doing it, all it knows is that it takes a message and turns it into a sequence of bytes. This independence greatly simplifies the interaction between objects in our implementation, they don't have to know about each other, they just communicate over the high level messages we defined earlier and that's all.

Given there are some well known patterns when building network messaging apps, Netty comes with a collection of base classes you can inherit when building your own stuff and we're using one of those here, the `MessageToByteEncoder`. This class defines an `encode` method that gives us the `ChannelHandlerContext` (for now, think about it as the collection of pipes we're using to communicate), the `ClientRequest` message and a `ByteBuf` object were we will write the data.

Our implementation here is just matching on the message code (which is faster than mathing on object type) and call the method to turn the message into a collection of bytes. The `@switch` is there because we want to make sure that the compiler will turn this into a Java `switch/case` operation, if we make a change to our code that prevents the compiler from generating a `switch/case`, compilation will fail and we will be able to fix this.

But what are we writing here? Let's look at how the common memcached packet is organized(the offset are positions in an array):

    | offset | description                                                           |
    | 0      | magic number indicating if server or client packet                    |
    | 1      | message type                                                          |
    | 2-3    | size of the key in this message (if there is one)                     |
    | 4      | extras length, some messages contain an extra field, that's it's size |
    | 5      | data type, not in use                                                 |
    | 6-7    | reserved field, not in use                                            |
    | 8-11   | total message body size (this includes the key size as well)          |
    | 12-15  | opaque field for operations that use it                               |
    | 16-23  | CAS field for operations that use it                                  |
    | 24-N   | bytes that symbolize the key that is being operated on                | 

For both `GET` and `DELETE` operations, this is the packet that we write. There's a bunch of control information at the top and our data starts at the 24th item. All packets sent to/from memcached have at least 24 bytes and all that changes betwen them is if there are extra fields (like we have at the `SET` message) and if it has a body other than the key value. For the `SET` operation, the packet would be:

    | offset | description                                                           |
    | 0      | magic number indicating if server or client packet                    |
    | 1      | message type                                                          |
    | 2-3    | size of the key in this message (if there is one)                     |
    | 4      | extras length, some messages contain an extra data, this is it's size |
    | 5      | data type, not in use                                                 |
    | 6-7    | reserved field, not in use                                            |
    | 8-11   | total message body size (this includes the key size as well)          |
    | 12-15  | opaque field for operations that use it                               |
    | 16-23  | CAS field for operations that use it                                  |
    | 24-27  | flags the client has defined for this key                             |
    | 28-31  | expiration defined for this key                                       |
    | 24-N   | bytes that symbolize the key that is being set, N is 24 + the key     |
    |        | size defined above                                                    |
    | N+1-Z  | bytes that represent the value that is being stored, it starts once   |
    |        | the key defined above ends and goes until (total size - key size)     |

The message format is mostly the same, the only difference is that now we have two extra fields and the value being set. With that, the code itself is self explanatory, we just turn our messages into bytes following both formats above.

## Decoding messages

Now that we know how to turn our messages into bytes, let's figure out how to do it backwards, turn the bytes written by the server into high level messages we can use. The piece of code responsible for this is the `MemcachedDecoder` class:

{% highlight scala %}
package memcached.netty

import io.netty.handler.codec.ByteToMessageDecoder
import io.netty.channel.ChannelHandlerContext
import io.netty.buffer.ByteBuf
import java.util
import memcached.netty.messages._
import scala.annotation.switch
import io.netty.util.CharsetUtil

class MemcachedDecoder extends ByteToMessageDecoder {

  def decode(ctx: ChannelHandlerContext, in: ByteBuf, out: util.List[AnyRef]) {

    if (in.readableBytes() >= 24) {
      in.markReaderIndex()

      in.readByte() // magic number
      val commandCode = in.readByte()
      val keyLength = in.readUnsignedShort()
      val extrasLength = in.readUnsignedByte()
      val dataType = in.readByte()
      val status = in.readShort()
      val bodyLength = in.readUnsignedInt()
      val opaque = in.readInt()
      val cas = in.readLong()

      if (in.readableBytes() >= bodyLength) {
        (commandCode: @switch) match {
          case Keys.Get => {
            val flags = if ( extrasLength > 0 ) {
              in.readInt()
            } else {
              0
            }

            val bytes = new Array[Byte](bodyLength.toInt - extrasLength)
            in.readBytes(bytes)

            val value = if (status == ServerResponse.Ok) {
              Some(bytes) -> None
            } else {
              None -> Some(new String(bytes, CharsetUtil.US_ASCII))
            }

            out.add(new GetResponse(value._1, status, flags, opaque, cas, value._2))
          }
          case _ if extrasLength == 0 => {
            val body = if (bodyLength > 0) {
              Some(in.toString(CharsetUtil.US_ASCII))
            } else {
              None
            }
            in.readerIndex((in.readerIndex() + bodyLength).toInt)
            out.add(new StatusResponse(commandCode, status, opaque, cas, body))
          }
          case _ => throw new UnknownResponseException(commandCode)
        }

      } else {
        in.resetReaderIndex()
      }
    }

  }

}
{% endhighlight %}

This one is also about the same size as the encoder and what it does isn't much different either. Now we inherit from a `ByteToMessageDecoder` class since we take a collection of bytes to turn it into a message.

First thing is to make sure we have at least 24 bytes to read. If there are less than 24 bytes we don't have a full message yet so there's no need to try and read it, just let the server write a bit more data. Once we get something that has at least 24 bytes, it's time for the action.

We start by marking the reader index, this means that we want to store at which byte we are before we start to read stuff from this collection. This is necessary because we don't know if we have a full message yet, we will only know it once we read the body size field so we leave the original index marked so we can get back to it in the future in case the body hasn't been fully read yet.

Now we read all fields from the packet header (they are the same as the ones we saw above for client packets). Once we finish, we check if the bytes available to read are at least as much as the message body we expect, if they are, we proceed to finish reading the message, if it isn't we reset the collection to it's original reader index and let the server write a bit more bytes.

The only special case we have now is the `GET` case because there are extra fields and the value could be there as well, so we have a special response for it, for all other cases, the `StatusResponse` is completely fine since all other commands will just check for the status field.

Writing encoders and decoders for well defined binary protocols like memcached's is dead simple, you just read the bytes and turn them into useful data. Fact that Netty already does all the connection and NIO weight lifting is also a huge advantage as our code gets to be extremely compact and to the point instead of having to handle selector loops, thread pooling and all that.

## Getting to the meat of the client

Now that we have the encoder and decoder in place, we can build the actual client that will be used by our code to talk to memcached. Given this class will be larger than all others, we'll have to break the discussion in two steps, let's look at the first part:

{% highlight scala %}
object NettyClient {

  InternalLoggerFactory.setDefaultFactory(new Slf4JLoggerFactory())
  val DefaultEventLoopGroup = new NioEventLoopGroup()
  val log = LoggerFactory.getLogger(classOf[NettyClient])

  def createBootstrap( handler: ChannelHandler ) = new Bootstrap()
    .group(DefaultEventLoopGroup)
    .channel(classOf[NioSocketChannel])
    .option[java.lang.Boolean](ChannelOption.SO_KEEPALIVE, true)
    .handler(new ChannelInitializer[io.netty.channel.Channel] {
    def initChannel(ch: Channel) {
      ch.pipeline().addLast(
        new MemcachedDecoder,
        new MemcachedEncoder,
        handler
      )
    }
  })

}
{% endhighlight %}

Here we define a bunch of the necessary magic for our client to work, first we set a reusable event loop group, using an `NioEventLoopGroup`. Netty allows you to use many different IO providers, but the most common so far is the NIO based one since if you're using Netty you usually want to build async networking clients. Here we also set the Netty logger so we can look at stuff that's happening in there.

Finally, the most important part here, the `createBootstrap` method. The `Bootstrap` in Netty serves as the builder object for creating channels that communicate over IO, it holds all the configuration needed to to setup your pipeline, like our encoder and decoder objects, the event loop group, the channel type (an NIO socket channel, in our case) and other options.

The last part of the method is including a `ChannelInitializer` that declares the order our pipeline works, the encoder/decoder order doesn't matter since they only work in one way, but the last part is the most important of them all, but it's important for them to come __before__ our final handler is declared because our handler doesn't understand `ByteBuf` objects, all it knows is the high level messages we defined above. So the order will (almost) always have protocol encoders/decoders first and then our actual handler last.

And now the actual client implementation:

{% highlight scala %}
class NettyClient(host: String = "localhost", port: Int = 11211)
  extends SimpleChannelInboundHandler[ServerResponse]
  with Client {

  import NettyClient._

  private val bootstrap = createBootstrap(this)

  private val connectPromise = Promise[Client]()
  private var disconnectFuture: Future[Client] = null

  private var currentContext: ChannelHandlerContext = null
  private var commandPromise: Promise[ServerResponse] = null

  def set(key: String, bytes: Array[Byte], flags: Int = 0, expiration: Int = 0): Future[StatusResponse] =
    this.write(new SetRequest(key, bytes, flags, expiration)).castTo[StatusResponse]

  def get(key: String): Future[GetResponse] =
    this.write(new GetRequest(key)).castTo[GetResponse]

  def delete(key: String) : Future[StatusResponse] =
    this.write(new DeleteRequest(key)).castTo[StatusResponse]

  def connect(): Future[Client] = {
    this.bootstrap.connect(host, port).onFailure {
      case e : Throwable => this.connectPromise.failure(e)
    }

    this.connectPromise.future
  }

  def close(): Future[Client] = {
    if (this.currentContext != null && this.currentContext.channel().isActive && this.disconnectFuture == null) {
      this.disconnectFuture = this.currentContext.close().map(v => this)
    }

    if (this.disconnectFuture == null) {
      Promise.success[Client](this).future
    } else {
      this.disconnectFuture
    }
  }

  private def write(request: ClientRequest): Future[ServerResponse] = {
    this.synchronized {
      if (this.commandPromise != null) {
        throw new BusyClientException
      }

      val result = Promise[ServerResponse]()

      this.currentContext.writeAndFlush(request).onFailure {
        case e: Throwable => result.tryFailure(e)
      }

      this.commandPromise = result
      this.commandPromise.future
    }
  }

  def channelRead0(ctx: ChannelHandlerContext, msg: ServerResponse) {
    this.synchronized {
      if (this.commandPromise != null) {
        if (msg.isError) {
          val exception = new CommandFailedException(msg)
          exception.fillInStackTrace()
          this.commandPromise.failure(exception)
        } else {
          this.commandPromise.success(msg)
        }
        this.commandPromise = null
      } else {
        log.error("Received response {} but had no promise to complete", msg)
      }
    }
  }

  override def exceptionCaught(ctx: ChannelHandlerContext, cause: Throwable) {
    log.error("Connection failed", cause)
    this.synchronized {
      if (this.commandPromise != null) {
        this.commandPromise.tryFailure(cause)
      }

      this.connectPromise.tryFailure(cause)
    }
  }

  override def handlerAdded(ctx: ChannelHandlerContext) {
    this.currentContext = ctx
    this.connectPromise.success(this)
  }
}
{% endhighlight %}

And here's the meat of the implementation. Our client inherits from `SimpleChannelInboundHandler` because it will do most of the event handling and heavy lifting required to make the pipeline work correctly, but you could just write your own handler implementation from scratch here as well, depends on how much you work you want to do. For our simple case, just inheriting from the inbound handler is more than enough, since we're only overriding 3 methods from the superclass.

Our class starts by declaring the promise fields we will use to handle communication. Again, all of this is async, so all communication and messages has to be handled in an async way as well, with promises and futures being returned and transformed everywhere, even for the connect action.

Let's look at `connect` first:

{% highlight scala %}
  def connect(): Future[Client] = {
    this.bootstrap.connect(host, port).onFailure {
      case e : Throwable => this.connectPromise.failure(e)
    }

    this.connectPromise.future
  }
{% endhighlight %}

Here we use the `bootstrap` we have to connect to the `host` and `port` fields we had defined before and if it fails it will call our `onFailure` hook and fail the connect promise. The method itself returns the future tied to our `connectPromise` instance variable. 

But hey, how come Netty, a Java project, has an implementation that returns a promise that has an `onFailure` handler? Well, it doesn't. The `connect` method at `Boostrap` returns a Netty's channel future but we wrote a nice implicit conversion from the channel future to our `Future[T]` implementation, let's check it:

{% highlight scala %}
package memcached

import io.netty.channel.{ChannelFutureListener, ChannelFuture}
import async.{Promise, Future}

object ChannelFutureTransformer {

  implicit def toFuture(channelFuture: ChannelFuture): Future[ChannelFuture] = {
    val promise = Promise[ChannelFuture]

    channelFuture.addListener(new ChannelFutureListener {
      def operationComplete(future: ChannelFuture) {
        if ( future.isSuccess ) {
          promise.success(future)
        } else {
          if ( future.cause() != null ) {
            promise.failure(future.cause())
          } else {
            val exception = new FailedFutureException(channelFuture)
            exception.fillInStackTrace()
            promise.failure(exception)
          }
        }
      }
    })

    promise.future
  }

}
{% endhighlight %}

While implicits have their own set of issues and complications, this is a powerful way to simplify our client code and make Netty's interface to be a bit more like what we already have. Instead of having to handle these channel futures in a different way, we just transform them into the `Future` objects we already know and use. Implicits in Scala are not to be feared, but you should use them judiciously.

So, now we know how our failure to connect to a `memcached` will fail the `Future` returned by `connect`, but where do we succeed the future? Let's find it!

{% highlight scala %}
  override def handlerAdded(ctx: ChannelHandlerContext) {
    this.currentContext = ctx
    this.connectPromise.success(this)
  }
{% endhighlight %}

And this is where we succeed our connection promise. When our handler is is finally connected to the server (and is ready to send and receive messages) this method is called with a connected `ChannelHandlerContext` that represents our full pipeline until the `memcached` server. Think about it as the pipes (including our encoders and decoders) to the server over the network. We hold this reference here as an instance variable because it's what we will use to send messages to the server. We write our messages here at the context and they will go through the pipes until the server.

To disconnect from a server, the implementation is a bit simpler:

{% highlight scala %}
  def close(): Future[Client] = {
    if (this.currentContext != null && this.currentContext.channel().isActive && this.disconnectFuture == null) {
      this.disconnectFuture = this.currentContext.close().map(v => this)
    }

    if (this.disconnectFuture == null) {
      Promise.success[Client](this).future
    } else {
      this.disconnectFuture
    }
  }
{% endhighlight %}

We basically check if we're connected and ask the handler to close the connection. If we're already disconnected (or were never connected) we just return an already succeeded promise.

Now let's get to the part where we actually talk to `memcached`:

{% highlight scala %}
  private def write(request: ClientRequest): Future[ServerResponse] = {
    this.synchronized {
      if (this.commandPromise != null) {
        throw new BusyClientException
      }

      val result = Promise[ServerResponse]()

      this.currentContext.writeAndFlush(request).onFailure {
        case e: Throwable => result.tryFailure(e)
      }

      this.commandPromise = result
      this.commandPromise.future
    }
  }
{% endhighlight %}

The write method is the only point where we interact with the channel context. Here we write a message to be sent to the server through our pipeline. First, we make sure we're not waiting for a response from the server already. Since the protocol itself isn't multiplexed, we can't safely send many commands at once to the server from a single client so we just lock it to only one pending command at a time.

Going forward, we create the promise that will hold the response when it comes and write the message. Here we just write one of `ClientRequest` subclasses, our `MemcachedEncoder` will do the work and turn it into the actual bytes. Since it's only one message, we use `writeAndFlush` and at the same time we register a handler to the channel future that is produced by this write. In this case, the only thing we care about is if we fail to write the message for some reason, so we only register a failure callback.

With that we set the promise as the current promise and return it's future. Since this method is private, let's look at who calls it inside our class:

{% highlight scala %}
  def set(key: String, bytes: Array[Byte], flags: Int = 0, expiration: Int = 0): Future[StatusResponse] =
    this.write(new SetRequest(key, bytes, flags, expiration)).castTo[StatusResponse]

  def get(key: String): Future[GetResponse] =
    this.write(new GetRequest(key)).castTo[GetResponse]

  def delete(key: String) : Future[StatusResponse] =
    this.write(new DeleteRequest(key)).castTo[StatusResponse]
{% endhighlight %}

The methods that call `write` are just creating the message objects and firing them. Here we also have the new `castTo` method that simplifies our promise handling. Since the command promise is a `Promise[ServerResponse]` object, we have to cast it to one of the `ServerResponse` subclasses and all that `castTo` does is perform this mapping. It's implementation at `Future[T` is extremely simple:

{% highlight scala %}
  def castTo[S](implicit executor: ExecutionContext): Future[S] = this.map(v => v.asInstanceOf[S])
{% endhighlight %}

We could write this code inside the `NettyClient` object, but it's much simpler to just have it at `Future`. 

Now that we know how writes work let's look at what reads look like:

{% highlight scala %}
  def channelRead0(ctx: ChannelHandlerContext, msg: ServerResponse) {
    this.synchronized {
      if (this.commandPromise != null) {
        if (msg.isError) {
          val exception = new CommandFailedException(msg)
          exception.fillInStackTrace()
          this.commandPromise.failure(exception)
        } else {
          this.commandPromise.success(msg)
        }
        this.commandPromise = null
      } else {
        log.error("Received response {} but had no promise to complete", msg)
      }
    }
  }
{% endhighlight %}

Even simpler, since all the byte decoding magic happens at `MemcachedDecoder` here we just grab the message and complete the promise, either with a success or a failure. As Netty allows us to separate our concerns clearly when building networked applications, our objects can focus on doing just one thing, just like our handler here that is mostly an orchestrator between client and server instead of having to care about encoding/decoding and all that.

And the only missing piece is the error handling:

{% highlight scala %}
  override def exceptionCaught(ctx: ChannelHandlerContext, cause: Throwable) {
    log.error("Connection failed", cause)
    this.synchronized {
      if (this.commandPromise != null) {
        this.commandPromise.tryFailure(cause)
        this.commandPromise = null
      }

      this.connectPromise.tryFailure(cause)
    }
  }
{% endhighlight %}

This method is called if something in our pipeline raises an exception, could be one of the encoders/decoders, a connection failure or anything like that. And what we do here is to try and fail the current command and the connection, since we don't know at which state this could have been raised. To be safe, just fail it all :)

## Talking to memcached

And here we are, let's look at how we can talk to memcached:

{% highlight scala %}
class ClientSpecification extends Specification {

  def toBytes(value: String): Array[Byte] = value.getBytes(CharsetUtil.US_ASCII)

  def fromBytes(bytes: Array[Byte]): String = new String(bytes, CharsetUtil.US_ASCII)

  def withClient[T](f: Client => T): T = {
    val client = new NettyClient()
    await(client.connect())
    try {
      f(client)
    } finally {
      await(client.close())
    }
  }

  def await[T](future: Future[T], seconds: Int = 3): T = {
    var count = 0
    while (!future.isCompleted && count <= seconds) {
      Thread.sleep(1000)
      count += 1
    }

    if (future.isCompleted) {
      future.value.get.get
    } else {
      throw new IllegalStateException(s"Trying to access the future did timeout after ${seconds} seconds")
    }
  }

  "client" should {

    "set a value and get it back correctly" in {
      withClient {
        client =>
          val unique = UUID.randomUUID().toString
          val key = s"hello-${unique}"
          val value = s"hello-world-${unique}"

          val result = await(client.set(key, toBytes(value)))
          result.isError must beFalse
          result.status === ServerResponse.Ok

          val response = await(client.get(key))
          fromBytes(response.value.get) === value
      }

    }

  }

}
{% endhighlight %}

You can see the full spec at the [project repo](https://github.com/mauricio/list-tutorial/blob/master/src/test/scala/memcached/ClientSpecification.scala), but here we can see how we interact with the promises and future objects we used to build our client.

It's not actually async, since we have to block for the tests to run, but still we talk to the server and get responses back in an async fashion and you could use this codebase to talk to a `memcached` server in an extremely simple way.

And now here we are, finally at the end of this tutorial, where you should have learned what and how to use promises and futures in your Scala projects and how you can use a library like Netty to build networked apps in a simple and intuitive fashion.