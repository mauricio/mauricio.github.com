---
layout: post
title: Building a simple long polling HTTP server with Scala and Netty
subtitle: because going low level HTTP is always fun
keywords: scala, netty, java, long polling, http
tags:
- useful
---

[You can find the whole source code for this example here.](https://github.com/mauricio/netty-long-polling-example)

While messaging solutions are abound, both over HTTP like web sockets and [server sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events) and using other protocols, sometimes you're stuck with an HTTP client that can't really do any of this funky stuff. Firewalls, proxies and many other hurdles along the way between clients and servers will force you to stick with the basic HTTP request-response cycle, but you still need to provide a way for clients to listen to events, this is where long polling comes into play.

The idea of long polling is that the client will perform a request, the server will receive it and leave it hanging for some time until an event arrives or the server decides it was a timeout (last time I checked Dropbox was working with a 20 seconds timeout). Doing something like this means the only thing your HTTP clients have to do is configure a really long timeout for the HTTP response, so they can just pretend this is a common HTTP connection. Proxies and firewalls will also just think this is a slow connection and will leave it be most of the time.

With the dead simple client, all the complication now needs to lie at the server.

## Netty comes to the rescue

To build an HTTP server that will suspend requests you'd either need something like the Servlet 3.0 API or just use a low level networking framework like [Netty](http://netty.io/), which is what we will use here. Our solution is going to be quite simple, clients perform a `GET` request and are suspended, when a `POST` request arrives for that same path, all suspended clients are notified with its contents as their HTTP response.

The first step here is to build our client's registry, where all clients will be registered when they make a request, let's start with its skeleton:

{% highlight scala %}
class ClientsRegistry(timeoutInSeconds: Int) {

  private val lock = new ReentrantLock()
  private val pathsToClients = scala.collection.mutable.Map[String, ListBuffer[ClientKey]]()
  private val orderedClients = scala.collection.mutable.TreeSet[ClientKey]()

  private def withLock[R](fn: => R)(implicit executor: ExecutionContext): Future[R] = {
    val p = Promise[R]

    executor.execute(new Runnable {
      override def run(): Unit = {
        lock.lock()
        try {
          p.success(fn)
        } catch {
          case e: Throwable => p.failure(e)
        } finally {
          lock.unlock()
        }
      }
    })

    p.future
  }

}
{% endhighlight %}

Our registry contains a lock, two collections and a method to execute a chunk of code, holding the lock, inside an execution context (like a thread pool). The lock exists because this class will be used concurrently by our server, so all access to it has to be thread safe. We could have used concurrent collections here, but it would make the implementation a bit more complicated, so we'll stick with the common ones and use the lock.

As we have a lock, we can't force clients to lock their threads so all operations will happen inside a provided execution context, in background, instead of forcing clients of this code to lock their threads (locking the Netty IO thread is a bad idea, so we avoid doing it at all costs). The method also wraps the function given and turns it into a future, so clients can either compose or wait on the future for its result.

But why do we need two collections here instead of just one?

Because of the timeouts problem. If we only had the map that maps paths to collections of clients, how could we figure out which clients need to be timeouted? We'd have to navigate through each one of them, check and if you happen to have lots of clients this is a pretty bad idea.

So we introduce a new collection, a *sorted set* that will return our clients in ascending order so we can quickly figure out which clients are going to timeout without walking through the whole collection.

Let's look at our `ClientKey` implementation:

{% highlight scala %}
case class ClientKey(path: String, expiration: Date, ctx : ChannelHandlerContext)
  extends Comparable[ClientKey] {

  override def compareTo(o: ClientKey): Int =
    expiration.compareTo(o.expiration)

  def isExpired : Boolean = new Date().after(expiration)

}
{% endhighlight %}

Our implementation is quite simple, it just holds the path, the expiration date and the context for this client (so we can write to it) and it implements `Comparable` using the expiration as the sorting value. This means all objects inside our `orderedClients` collection will be sorted by expiration date in ascending order. We'll see how this affects our timeout implementation soon.

## Registering clients

Our fist operation is to receive a client and register it under an specific path, let's look at it:

{% highlight scala %}
def calculateTimeout(): Date = {
  val calendar = Calendar.getInstance
  calendar.add(Calendar.SECOND, timeoutInSeconds)

  calendar.getTime
}

def registerClient(path: String, ctx: ChannelHandlerContext)(implicit executor: ExecutionContext): Future[ClientKey] =
  withLock {
    val client = ClientKey(path, calculateTimeout(), ctx)

    val clients = pathsToClients.getOrElseUpdate(path, ListBuffer[ClientKey]())
    clients += client
    orderedClients += client

    client
  }
{% endhighlight %}

When registering clients, we first create a new `ClientKey` object calculating its timeout (we use the value provided by the registry's constructor) and append it to both the map and set inside our class. Since the `withLock` method requires an `ExecutionContext` our `registerClient` method will also need one to be provided.

## Completing clients

The second operation is to complete a path, it means a `POST` request came and now all clients for that specific path need to be removed from the registry so we can send them the response. Here's the implementation:

{% highlight scala %}
def complete(path: String)(implicit executor: ExecutionContext): Future[Iterable[ClientKey]] =
  withLock {
    pathsToClients.remove(path).map {
      clients =>
        orderedClients --= clients
        clients
    }.getOrElse(Iterable.empty)
  }
{% endhighlight %}

The implementation here is dead simple, first find all clients for an specific path, remove all clients from the timeouts collection (`orderedClients`) and then return the clients found. If nothing is found just return an empty collection.

Again, as we're using `withLock` an execution context must be provided.

## Timeouting clients

The last important operation we need is the timeout, let's look at the code:

{% highlight scala %}
def collectTimeouts()(implicit executor: ExecutionContext): Future[Iterable[ClientKey]] = {
  withLock {
    val iterator = orderedClients.iterator
    val timeouts = ListBuffer[ClientKey]()

    var done = false

    while (iterator.hasNext && !done) {
      val next = iterator.next()
      if (next.isExpired) {
        timeouts += next
      } else {
        done = true
      }
    }

    orderedClients --= timeouts

    timeouts.foreach {
      timeout =>
        pathsToClients.get(timeout.path).foreach(b => b -= timeout)
    }

    timeouts
  }
}
{% endhighlight %}

You might be looking at that explicit iterator and thinking _OMG, why do we need this?_ Think about it. We can't be wasting CPU cycles evaluating all clients to verify if they have timeouted or not and our `orderedClients` set is sorted by expiration in ascending order.

What does that mean?

That as soon as I find an item that is not expired, it means *there are no more expired items to be removed*. So only *one* comparison is wasted here, the one that produces the first item that isn't expired. As long as I'm seeing items that are expired I'm good because I do want to remove these items, once I find the first item that is not expired I break the loop and move on.

So this is why we use a `TreeSet` here, so we can quickly find the clients to be timeouted in as little comparisons as possible. Later we also remove them from their respective paths (this is why we also save the `path` at clients) and at the end return them to the caller.

Our client registry is now done, you can find [the specs for the registry implememtation here](https://github.com/mauricio/netty-long-polling-example/blob/master/src/test/scala/example/ClientsRegistrySpec.scala).

## Building our Netty handler

In Netty most of your work happens inside of channel handlers, in our case, as a server, we're going to build a [ChannelInboundHandler](http://netty.io/4.0/api/io/netty/channel/ChannelInboundHandler.html). As we're building an HTTP server, we can just assume someone will do all the parsing for us and we'll receive a [FullHttpRequest](http://netty.io/4.0/api/io/netty/handler/codec/http/FullHttpRequest.html). Netty also comes with many base classes available so we don't really need to implement the full `ChannelInboundHandler` interface, we can inherit from [SimpleChannelInboundHandler](http://netty.io/4.0/api/io/netty/channel/SimpleChannelInboundHandler.html) and implement the `channelRead0` method to be done with it, let's look at our `MainHandler` implementation:

{% highlight scala %}
@Sharable
class MainHandler( registry : ClientsRegistry )(implicit executor: ExecutionContext)
  extends SimpleChannelInboundHandler[FullHttpRequest] {

  import MainHandler.log

  override def channelRead0(ctx: ChannelHandlerContext, msg: FullHttpRequest): Unit = {

    msg.getMethod match {
      case HttpMethod.GET => {
        registry.registerClient(msg.getUri, ctx).onFailure {
          case e => writeError(ctx, e)
        }
      }
      case HttpMethod.POST => {
        ReferenceCountUtil.retain(msg)
        registry.complete(msg.getUri).onComplete {
          result =>
            try {
              result match {
                case Success(clients) => {
                  clients.foreach {
                    client =>
                      client.ctx.writeAndFlush(buildResponse(msg))
                  }
                  ctx.writeAndFlush(new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK))
                }
                case Failure(e) =>
                  writeError(ctx, e)
              }
            } finally {
              ReferenceCountUtil.release(msg)
            }
        }
      }
      case _ =>
        ctx.writeAndFlush(new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.NOT_FOUND))
    }
  }

}
{% endhighlight %}

The very first thing here is the `@Sharable` annotation for our handler, this means it can be used by many different channels at the same time and its *really* important for you to correctly mark your handlers as Netty will use this information to decide if it can reuse your handler in many different channels and threads.

Just like the client's registry takes an execution context for its methods, our handler takes one when it's being created so it can provide it to the registry methods. You can then provide any thread pool you'd like.

Now let's look at the first case:

{% highlight scala %}
case HttpMethod.GET => {
  registry.registerClient(msg.getUri, ctx).onFailure {
    case e => writeError(ctx, e)
  }
}  
{% endhighlight %}

Since we're going really low level here, there's no such thing as a router for our requests, we need to either build one or just match the routes as we'd like to. In this case it's quite simple, we just use any `GET` or `POST` requests and move on. The `GET` implementation also happens to be the simplest, we just register the client that made it or make sure we provide an error message if we can't.

This sends us to the meat of the handler, the `POST` operation:

{% highlight scala %}
case HttpMethod.POST => {
  ReferenceCountUtil.retain(msg)
  registry.complete(msg.getUri).onComplete {
    result =>
      try {
        result match {
          case Success(clients) => {
            clients.foreach {
              client =>
                client.ctx.writeAndFlush(buildResponse(msg))
            }
            ctx.writeAndFlush(new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK))
          }
          case Failure(e) =>
            writeError(ctx, e)
        }
      } finally {
        ReferenceCountUtil.release(msg)
      }
  }
}  
{% endhighlight %}

There's a lot of stuff going on. First, we have the use of `ReferenceCountUtil`. In Netty some objects are reference counted inside the framework itself, this is done so they can be reused across different requests, diminishing the pressure at the JVM's garbage collector. And while this improves throughput it requires us, the developers, to do the bookkeeping.

Most of the time you can ignore these objects are reference counted, but in our case the actual implementation of the handler (the one that writes the response to clients) happens in a different thread than the one that is being used by Netty (the `complete` method doesn't return right away, it produces a `Future[Iterable[ClientKey]]`), if we didn't call `retain` here Netty would assume the request was _consumed_ by our code and would gladly reuse it, which would break our server or worse, produce bogus responses.

So, as we need to hold onto this request for a while, we call `retain` on it and only call `release` at the `finally` block of the callback we registered at the future that was produced by the `complete` call. When we actually enter the callback implementation we can see it's quite simple, if it finds a list of clients for the given path, it sends the results for each one of them and sends response to the `POST` client, if it fails the `POST` client receives an error message.

The interaction between these two HTTP methods (`GET` and `POST`) is what is actually building our long polling client. When a `GET` arrives we don't answer right away, we register the client and wait for someone to provide a `POST`, once it arrives we find all registered clients, remove them from the registry and send the response to them. Dead simple.

Another important piece for this handler is the timeouts collector:

{% highlight scala %}
def evaluateTimeouts(): Unit = {
  registry.collectTimeouts().onSuccess {
    case clients => clients.foreach {
      client =>
        writeError(client.ctx, new TimeoutException("channel timeouted without a response"))
    }
  }
}
{% endhighlight %}

Simple as well, just collect the expired clients and write a timeout error to them.

The other helper methods aren't that much special:

{% highlight scala %}
def writeError(ctx : ChannelHandlerContext, e : Throwable): Unit = {
  val response = new DefaultFullHttpResponse(
    HttpVersion.HTTP_1_1,
    HttpResponseStatus.INTERNAL_SERVER_ERROR,
    Unpooled.wrappedBuffer(e.getMessage.getBytes(CharsetUtil.UTF_8))
  )

  response.headers().add(HttpHeaders.Names.CONTENT_TYPE, "text/plain")

  ctx.writeAndFlush(response)
}

def buildResponse( request : FullHttpRequest ) : FullHttpResponse = {
  val response = new DefaultFullHttpResponse(
    HttpVersion.HTTP_1_1,
    HttpResponseStatus.OK,
    Unpooled.copiedBuffer(request.content())
  )

  if ( request.headers().contains(HttpHeaders.Names.CONTENT_TYPE) ) {
    response.headers().add(HttpHeaders.Names.CONTENT_TYPE, request.headers().get(HttpHeaders.Names.CONTENT_TYPE))
  }

  response
}  
{% endhighlight %}

One writes an exception as an HTTP server error and the other gets the `POST` request and creates a new response based on it so we can send it to our registered clients.

[You can find tests for the handler here](https://github.com/mauricio/netty-long-polling-example/blob/master/src/test/scala/example/MainHandlerSpec.scala). Our server is almost done!

## HTTP housekeeping

As we're using a low level HTTP framework for our server, it won't really do anything we don't ask it to. Stuff like defining the right value for the `Connection` header, setting `Content-Length` for responses and using the same HTTP version as the client needs to be done by us. Fortunately, Netty offers a nice way for us to plug a handler that will do this without polluting our main handler, let's look at it:

{% highlight scala %}
object SetHeadersHandler {

  val DefaultServerName = "long-polling-server-example"
  val ConnectionAttribute =
    AttributeKey.valueOf[String](s"${SetHeadersHandler.getClass.getName}.connection")
  val HttpVersionAttribute =
    AttributeKey.valueOf[HttpVersion](s"${SetHeadersHandler.getClass.getName}.version")

}

@Sharable
class SetHeadersHandler extends ChannelDuplexHandler {

  import SetHeadersHandler._

  override def channelRead(ctx: ChannelHandlerContext, msg: scala.Any): Unit = {
    msg match {
      case request: FullHttpRequest => {
        val connection = if (HttpHeaders.isKeepAlive(request))
          HttpHeaders.Values.KEEP_ALIVE
        else
          HttpHeaders.Values.CLOSE
        ctx.channel().attr(ConnectionAttribute).set(connection)
        ctx.channel().attr(HttpVersionAttribute).set(request.getProtocolVersion)
      }
      case _ =>
    }

    super.channelRead(ctx, msg)
  }

  override def write(ctx: ChannelHandlerContext, msg: scala.Any, promise: ChannelPromise): Unit = {

    msg match {
      case response: FullHttpResponse => {
        response.setProtocolVersion(ctx.channel().attr(HttpVersionAttribute).get())
        response.headers().set(HttpHeaders.Names.SERVER, DefaultServerName)
        response.headers().set(HttpHeaders.Names.CONNECTION, ctx.channel().attr(ConnectionAttribute).get())
        response.headers().set(HttpHeaders.Names.CONTENT_LENGTH, response.content().readableBytes())
      }
      case _ =>
    }

    super.write(ctx, msg, promise)
  }
}  
{% endhighlight %}

A `ChannelDuplexHandler` is a handler for both inbound and outbound messages, so HTTP request and response objects. Our handler is again marked as `@Sharable` as it can be reused by many different channels and threads at the same time, to accomplish that we use the channel attributes collection to store the `Connection` and `HTTP version` values for the request so we can set them up at the response. This guarantees that any request that comes in will correctly fill in the necessary attributes and we will be able to use these values when building the response.

At the `write` method we basically pull the fields that were set by `channelRead`, include a `Server` and calculate the `Content-Length` (if you don't set a content length clients will have trouble figuring out that your response is over) and then wrap it up calling the superclass implementation. This guarantees our HTTP responses are sane and match what the client expected to receive back and we didn't have to pollute our main handler with any of this. This is one of the main beauties of the Netty API, you can just compose new functionalities on top of your networking code by introducing more handlers along the way.

[Check out the tests for the set headers handler](https://github.com/mauricio/netty-long-polling-example/blob/master/src/test/scala/example/SetHeadersHandlerSpec.scala).

## Starting the server

And as the final step we need an initializer that will start our HTTP server:

{% highlight scala %}
class Initializer (timeoutInSeconds : Int, val port: Int) (implicit executor: ExecutionContext)
  extends ChannelInitializer[SocketChannel] {

  import Initializer.log

  private val bossGroup = new NioEventLoopGroup(1)
  private val workerGroup = new NioEventLoopGroup()

  private val serverBootstrap = new ServerBootstrap()
  serverBootstrap.option(ChannelOption.SO_BACKLOG, java.lang.Integer.valueOf(1024))
  serverBootstrap.group(bossGroup, workerGroup)
    .channel(classOf[NioServerSocketChannel])
    .childHandler(this)

  private var serverChannel: Channel = null
  private val setHeadersHandler = new SetHeadersHandler
  private val mainHandler = new MainHandler(new ClientsRegistry(timeoutInSeconds))

  override def initChannel(ch: SocketChannel): Unit = {
    val p = ch.pipeline()

    p.addLast("http-codec", new HttpServerCodec())
    p.addLast("aggregator", new HttpObjectAggregator(Int.MaxValue))
    p.addLast("set-headers-handler", setHeadersHandler)
    p.addLast("handler", mainHandler)
  }

  def start(): Unit = {
    try {
      serverChannel = serverBootstrap.bind(port).sync().channel()
      serverChannel.eventLoop().scheduleAtFixedRate(new Runnable {
        override def run(): Unit =
          mainHandler.evaluateTimeouts()
      },
        timeoutInSeconds,
        timeoutInSeconds,
        TimeUnit.SECONDS
      )

      log.info(s"Starting server ${serverChannel}")
      serverChannel.closeFuture().sync()
    } catch {
      case e: Exception =>
        log.error(s"Server channel failed with ${e.getMessage}", e)
    }
    finally {
      bossGroup.shutdownGracefully()
      workerGroup.shutdownGracefully()
    }
  }

  def stop(): ChannelFuture = {
    log.info(s"Stopping server ${serverChannel}")
    val channelFuture = serverChannel.close().awaitUninterruptibly()
    log.info(s"Closed server channel ${serverChannel}")
    channelFuture
  }

}  
{% endhighlight %}

The initializer itself is the piece that glues all Netty pieces together. The server backlog (the listener), the event loops and the channel pipeline. Here we setup our server and the pieces it is made of, the most important method is `initChannel`:

{% highlight scala %}
override def initChannel(ch: SocketChannel): Unit = {
  val p = ch.pipeline()

  p.addLast("http-codec", new HttpServerCodec())
  p.addLast("aggregator", new HttpObjectAggregator(Int.MaxValue))
  p.addLast("set-headers-handler", setHeadersHandler)
  p.addLast("handler", mainHandler)
}  
{% endhighlight %}

This is where we introduce the many pieces that make our pipeline and ordering here is *very important*. If we change the order of any of the pieces here, we could be breaking our server. Our pipeline starts with an `HttpServerCodec`, that parses HTTP requests and produces HTTP responses. It then has an `HttpObjectAggregator`, this aggregator turns the various HTTP messages that Netty produces into the `FullHttpRequest` we have been working with. Without this you would have to manually handle the many HTTP messages you would receive instead.

Then we start to reach application code with the `SetHeadersHandler` and finally our `MainHandler` at the end of the pipeline. This `initChannel` method is called whenever a new channel is created, the Netty provided HTTP codecs can't be reused so we need to have one of them for every channel available but our own handlers are all `@Sharable` so we can just reuse them instead of creating new ones.

The other important piece here is the scheduler:

{% highlight scala %}
serverChannel.eventLoop().scheduleAtFixedRate(new Runnable {
  override def run(): Unit =
    mainHandler.evaluateTimeouts()
},
  timeoutInSeconds,
  timeoutInSeconds,
  TimeUnit.SECONDS
)  
{% endhighlight %}

At our `MainHandler` earlier we saw the `evaluateTimeouts` method but we didn't see it being called, this is because it was supposed to be called here at the initializer using a scheduler. Every Netty event loop is capable of scheduling events and you should just use them here to evaluate the timeouts. In here we're just using the actual timeout value to perform the evaluations but you could also use a fraction of it to detect timeouts faster.

[You can find an initializer test here](https://github.com/mauricio/netty-long-polling-example/blob/master/src/test/scala/example/InitializerSpec.scala).

## It is alive!

And now you have a basic and functional long polling HTTP server that you can extend to your own needs!
