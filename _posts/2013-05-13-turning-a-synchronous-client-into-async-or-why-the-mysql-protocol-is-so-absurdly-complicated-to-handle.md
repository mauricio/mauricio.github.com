---
layout: post
title: Turning a synchronous client into async or why the MySQL protocol is so complicated to handle
---

A week ago I released the first version of the [postgresql-async](https://github.com/mauricio/postgresql-async) project
and got some feedback from people that were looking for something like this but for MySQL. Since I had already planned
to do it sometime in the future, why not just start it now? It wouldn't be much harder than PostgreSQL, would it?

Oh boy, I was never THIS wrong in my life.

As you might have seen from the project description, I'm using [Netty](http://netty.io/) as the IO framework for both
clients. Netty follows a messaging approach to IO, when something happens, an event is created and eventually your code
will receive this event and respond to it in some way. Since all that comes and goes from sockets are bytes, you need
to make sense of them in some way and, when using Netty, you can build upon a simple abstraction to do this. Let's
see some code from the `PostgreSQLConnectionHandler` class:

{% highlight scala linenos %}
this.bootstrap.setPipelineFactory(new ChannelPipelineFactory() {

  override def getPipeline(): ChannelPipeline = {
    Channels.pipeline(
      new MessageDecoder(configuration.charset, configuration.maximumMessageSize),
      new MessageEncoder(configuration.charset, encoderRegistry),
      PostgreSQLConnectionHandler.this)
  }

})
{% endhighlight %}

A channel pipeline, as the name implies, is a sequence of handlers that will process the IO events. If you have done
servlets, it's akin to a filter chain (or a middleware stack on Rack, for instance), each object in the pipeline is invoked
with an event and can process, discard or send it forward for someone else to process. In this case, we have a very
basic pipeline, a `MessageEncoder`, a `MessageDecoder` and the `PostgreSQLConnectionHandler` itself as the end of the line.

## Decoding a message

These classes are exactly what they look like, the `MessageDecoder` turns a bunch of bytes sent by the server into a
meaningful object. If your server emits a warning, it becomes a `NoticeMessage`, this way, all the code to handle
turning collections of bytes into messages live at the `MessageDecoder`, the driver code itself only works with high
level messages, leaving all the heavy lifting for the decoder to do.

PostgreSQL defines a nice format for it's messages, each message is composed of:

* message type = 1 byte
* message size (including self) = 4 bytes
* message body = (message size) - 4 bytes

In Netty lingo, we call this a **frame**, it's a common pattern on network apps communication, you say "this message has
N bytes, so wait until you have N bytes available and process it", this simplifies buffering and processing because you
don't have to wait for a terminator and the sender doesn't have to escape the data in any way, you just read until N bytes
and you're done.

As this is commonplace in network apps, Netty offers a `FrameDecoder` class that you can subclass and build your own, here's
how it looks like in the PostgreSQL driver:

{% highlight scala linenos %}
class MessageDecoder(charset: Charset, maximumMessageSize : Int = MessageDecoder.DefaultMaximumSize) extends FrameDecoder {

  private val parser = new MessageParsersRegistry(charset)

  override def decode(ctx: ChannelHandlerContext, c: Channel, b: ChannelBuffer): Object = {

    if (b.readableBytes() >= 5) {

      b.markReaderIndex()

      val code = b.readByte()
      val lengthWithSelf = b.readInt()
      val length = lengthWithSelf - 4

      if (b.readableBytes() >= length) {
        code match {
          case ServerMessage.Authentication => {
            AuthenticationStartupParser.parseMessage(b)
          }
          case _ => {
            parser.parse(code, b.readSlice(length))
          }
        }

      } else {
        b.resetReaderIndex()
        return null
      }

    } else {
      return null
    }

  }

}
{% endhighlight %}

It's really simple, wait until we have at least 5 bytes (message type and length), once we have at least 5, read the
type, then read size. With size in hand, check if we have at least (size - 4) bytes to read, if we do, read the slice
needed and feed it to the message specific decoder so it can send the message forward. If we don't have enough bytes,
just "unread" the buffer and give it back.

These steps are repeated until you disconnect the client. The class is both simple and, most importantly, **stateless**.
This message decoder does not have any mutable state, the state that the connection needs to maintain is kept farther
down the pipeline to where it really makes sense to have state.

This makes it really easy to pinpoint bugs and errors, since there is only one possible state for the decoder, if it
breaks, it will break on **all** cases and not in just one very specific and state dependent one. Better yet, since
there is no mutable state, you can't have concurrency issues! This class is thread safe by default and could be shared
between different concurrent threads at any moment.

Why am I saying this? Because now we get to see how the MySQL network protocol works.

**DISCLAIMER**: this is a rant about MySQL's network protocol only. I am very grateful for all the work everyone involved
in MySQL did and it still is my database of choice if not on Heroku so, don't take this as another 'mysql sucks, bla bla bla'
post, I just think it's important for people to understand how you can complicate someone else's life with a complicated
network protocol.

## Decoding MySQL messages

For the MySQL client I built the [MySQLFrameDecoder](https://github.com/mauricio/postgresql-async/blob/master/mysql-async/src/main/scala/com/github/mauricio/async/db/mysql/codec/MySQLFrameDecoder.scala)
class. The message protocol is a bit different from the PostgreSQL protocol as we work with "packets" and not messages
per se (and the protocol uses the little endian byte order). Packets are made of:

* packet length - 3 bytes
* sequence number - 1 byte
* payload - packet length bytes

You might be thinking, "where is the packet type field?", well, there isn't one. The closest thing you would have to this
are the "generic response packets":

* [OK_Packet](http://dev.mysql.com/doc/internals/en/overview.html#packet-OK_Packet)
* [ERR_Packet](http://dev.mysql.com/doc/internals/en/overview.html#packet-ERR_Packet)
* [EOF_Packet](http://dev.mysql.com/doc/internals/en/overview.html#packet-EOF_Packet)

But this is a very loose assumption since [the documentation itself](http://dev.mysql.com/doc/internals/en/overview.html#packet-EOF_Packet)
says:

    the EOF packet may appear in places where a Protocol::LengthEncodedInteger may appear. You have to check the packet length is less then 9 to make sure it is a EOF packet.

And this is also the case for the `OK_Packet` since you can get something that looks like an OK while doing prepared statements
but it won't be one, it will be a [result set row](http://dev.mysql.com/doc/internals/en/prepared-statements.html#binary-protocol-resultset-row).

What does this all mean? Different than the PostgreSQL protocol, where the parser knew right away what kind of message it
was handling, on MySQL we don't have this kind of information, the parser needs context, it needs to know "what am I doing
now?" to be able to process the messages and this is bad.

First, now we have state in two different places, the message decoder and the `MySQLConnectionHandler`. Then a query
message is received, the connection handler has to ping the decoder and say "hey, we're in query phase, switch the
way you handle messages" and this same decoder also needs to know when this phase ends, clear it's internal state and
then move on to the next sequence of commands. As you might imagine, this is a concurrency nightmare, you have a lot of
mutable state and there is no way to hide from it, that's how the protocol was built and it's unlikely it will change
in the long run.

But it's still not enough. When you send a statement, MySQL will respond with a text based response, which means all rows
will be turned into string values and the driver has to decode them back to their original values. If you use a prepared
statement, MySQL will answer with a binary formatted result set. All fields will be encoded as their byte representations
and you need to switch to this "decoding" mode by yourself at your parser.

Not only we have a protocol made for sequential programming, the protocol lacks consistency between it's communication
mechanisms. Instead of having only one way to represent a result set during a connection (like PostgreSQL does, you can
set if you want all results to be text or binary based) MySQL again puts state into the protocol and forces the driver
to understand how to parse data in two different ways. Not funny if you are the guy building the driver.

## Why is MySQL like that?

When you switch from a synchronous model to an asynchronous one, the way you think about communication changes. The MySQL network
protocol is a classic example of imperative and sequential programming. Here's how doing a prepared statement in MySQL
would look in pseudo code:

{% highlight scala linenos %}
 socket.COM_STMT_PREPARE("select 10")
 val prepareResponsePacket = socket.readPacket()

if ( prepareResponsePacket == ERR_Packet ) {
 fail(prepareResponsePacket)
}

val paramsCount = socket.readPacket().numParams
val params = []
val columnsCount = socket.readPacket().numColumns
val columns = []

for ( x = 0; x < paramsCount; x++ ) {
    params.push(socket.readPacket())
}

socket.readPacket() // EOF to parameters

for ( x = 0; x < columnsCount; x++ ) {
    columns.push(socket.readPacket())
}

socket.readPacket() // EOF to columns

socket.COM_STMT_EXECUTE(prepareResponsePacket.statementId)

val executeResponse = socket.readPacket()

if executeResponse == OK_Packet
    emptyResponse()
elsif executeResponse == ERR_Packet
    fail(executeResponse)
else
    processResultSetPackets(socket)
end
{% endhighlight %}

When you're building synchronous code that follows a sequence, it's rather easy to have it built like that. You are already
at the "state" necessary to perform the other actions so it becomes natural for you to keep this state and just go on like
that. While in PostgreSQL you need to peek at the message to know what it is, in MySQL you need to understand "where" you
are and in an async model this becomes blurry, because you just can't chain methods one after the other as with the
synchronous solution just above.

Also, this kind of solution not only makes it harder for someone to go async, but it also makes it harder to separate the
"workflow" of the app from the resources it uses. Since you need to keep a handle to the socket connection available inside
the code to keep on reading, it makes it harder to test this stuff in isolation.

## A synchronous mind in an asynchronous world

Building asynchronous solutions might look like a panacea, but when the protocol doesn't lend itself to asynchronous
programming, like the MySQL network protocol, it might become much harder to reason and to work with. If you ever have to
build a direct-to-sockets network communication solution, keep this in mind and don't just let the "sequential" model
go into the code, as you might make life harder for someone else to implement a solution in the future.

Still, after all that, the MySQL driver is almost complete and will have a first release soon, stay tuned!