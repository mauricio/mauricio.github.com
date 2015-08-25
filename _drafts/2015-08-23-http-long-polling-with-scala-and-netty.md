---
layout: post
title: Building a simple long polling HTTP server with Scala and Netty
subtitle: because going low level HTTP is always fun
keywords: scala, netty, java, long polling, http
tags:
- useful
---

[You can find the whole source code for this example here](https://github.com/mauricio/netty-long-polling-example).

While messaging solutions are abound, both over HTTP like web sockets and [server sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events) and using other protocols, sometimes you're stuck with an HTTP client that can't really do any of this funky stuff. Firewals, proxies and many other hurdles along the way between clients and servers will force you to stick with the basic HTTP response cycle, but you still need to provide a way for clients to listen to events, this is where long polling comes into play.

The idea of long polling is that the client will perform a request, the server will receive it and leave it hanging for some time until an event arrives or the server decides it was a timeout (last time I checked Dropbox was working on a 20 seconds timeout). Doing something like this means the only thing your HTTP clients have to do is configuring a really long timeout for the HTTP response so they can just pretend this is a common HTTP connection. Proxies and firewalls will also just think this is a slow connection and will leave it be most of the time.

With the dead simple client, all the complication now needs to lie at the server.

## Netty comes to the rescue

To build an HTTP server that will suspend requests you'd either need something like the Servlet 3.0 API or just use a low level networking framework like [Netty](http://netty.io/), which is what we will use here. Our solution is going to be quite simple, clients perform a `GET` request and are suspended, when a `POST` request arrives for that same path, all suspended clients are notified with it's contents with an HTTP response.

The first step here is to build our clients registry, where all clients will be registered when they make a request, let's start with it's skeleton:

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

As we have a lock, we can't force clients to lock their threads to all operations will happen inside a provided execution context, in background, instead of forcing clients of this code to lock their threads (locking the Netty IO thread is a bad idea, so we avoid doing it at all costs). The method also wraps the function given and turns it into a future, so clients can either compose or wait on the future for it's result.

But why do we need two collections here instead of just one?

Because of the timeouts problem. If we only had the map that maps paths to collections of clients, how could we figure out which clients need to be timeouted? We'd have to navigate through each one of them and check and if you happen to have lots of clients this is a pretty bad idea.

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

When registering clients, we first create a new `ClientKey` object calculating it's timeout (we use the value provided by the registry's constructor) and append it to both the map and set inside our class. All

## Completing clients

The second operation is to complete a path, it means a `POST` request came and now all clients for that specific path need to be removed from the registry so we can send them the response. Here's the implementation:

{% highlight scala %}

{% endhighlight %}









.
