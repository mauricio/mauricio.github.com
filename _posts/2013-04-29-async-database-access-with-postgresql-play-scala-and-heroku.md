---
layout: post
title: Async database access with PostgreSQL, Play, Scala and Heroku
---

Last year I felt I wanted to contribute in some way to the Scala community. Since I didn't think I was smart
enought to work on the main libraries or compiler, I started to look for something that I could build and
would benefit me and the community in general. I started looking around and noticed that there weren't async
drivers for the good old relational databases. If you're fancy and you're using one of the new NoSQL ones,
you are most likely covered, but if you still rely on databases like PostgreSQL (like I do at my daily job),
 you have to rely on the official (and blocking) PostgreSQL JDBC driver and so the
[postgresql-async project](https://github.com/mauricio/postgresql-async) was born.

I started looking at what people did in the NodeJS community like [node-postgres](https://github.com/brianc/node-postgres)
and I noticed you don't really need the full JDBC implementation for a usable database driver, as long as you
can execute statements and get something back, you probably have all you need so this was the goal. Build something
that would allow you to execute queries and get results back.

## Connecting to the database

Let's see some sample usage:

{% highlight scala linenos %}
import com.github.mauricio.async.db.postgresql.PostgreSQLConnection
import com.github.mauricio.async.db.util.ExecutorServiceUtils.CachedExecutionContext
import com.github.mauricio.async.db.util.URLParser
import com.github.mauricio.async.db.{RowData, QueryResult, Connection}
import scala.concurrent.duration._
import scala.concurrent.{Await, Future}

object BasicExample {

  def main(args: Array[String]) {

    val configuration = URLParser.parse("jdbc:postgresql://localhost:5233/my_database?username=postgres&password=somepassword")
    val connection: Connection = new PostgreSQLConnection(configuration)

    Await.result(connection.connect, 5 seconds)

    val future: Future[QueryResult] = connection.sendQuery("SELECT 0")

    val mapResult: Future[Any] = future.map(queryResult => queryResult.rows match {
      case Some(resultSet) => {
        val row : RowData = resultSet.head
        row(0)
      }
      case None => -1
    }
    )

    val result = Await.result( mapResult, 5 seconds )

    println(result)

    connection.disconnect

  }


}
{% endhighlight %}

The basic usage pattern is quite simple, you ask for something, you get a `Future[_]` back. In this case,
I'm simplifying the code by blocking to get the results, but if you're using an async framework (like Akka or
Play) you can just compose on these futures to do your work.

The `PostgreSQLConnection` is a real connection to the database, it implements the `Connection` trait and
you should try to use the trait as much as possible. When you create a connection handler, it's not connected
to the database yet, you have to connect it yourself calling `connect` and waiting for the future to return or
composing on the future to do something else.

When you execute a statement, you get back a `QueryResult` object that might or might not contain a `ResultSet`.
That depends on the kind of statement you executed, if the statement you asked for returns rows, there will be
a `ResultSet` available for you, if it does not then you will have a `None` in there.

## Integrating to a Play 2 application and running it on Heroku

Now if you're building a webapp and using Play you can avoid all that messy `Await.result()` stuff and just
return the futures themselves (you can see the full source code for this app
[here](https://github.com/mauricio/postgresql-async-app)).

Let's start creating a model:

{% highlight scala linenos %}
package models

import org.joda.time.LocalDate

case class Message ( id : Option[Long], content : String, moment : LocalDate = LocalDate.now() )
{% endhighlight %}

Now let's wrap the database access in a class to simplify the controllers:

{% highlight scala linenos %}
package models

import scala.concurrent.Future
import org.joda.time.LocalDate
import com.github.mauricio.async.db.{RowData, Connection}
import com.github.mauricio.async.db.util.ExecutorServiceUtils.CachedExecutionContext

object MessageRepository {
  val Insert = "INSERT INTO messages (content,moment) VALUES (?,?) RETURNING id"
  val Update = "UPDATE messages SET content = ?, moment = ? WHERE id = ?"
  val Select = "SELECT id, content, moment FROM messages ORDER BY id asc"
  val SelectOne = "SELECT id, content, moment FROM messages WHERE id = ?"
}

class MessageRepository(pool: Connection) {

  import MessageRepository._

  def save(m: Message): Future[Message] = {

    m.id match {
      case Some(id) => pool.sendPreparedStatement(Update, Array(m.content, m.moment, id)).map {
        queryResult => m
      }
      case None => pool.sendPreparedStatement(Insert, Array(m.content, m.moment)).map {
        queryResult => new Message(Some(queryResult.rows.get(0)("id").asInstanceOf[Long]), m.content, m.moment)
      }
    }

  }

  def list: Future[IndexedSeq[Message]] = {

    pool.sendQuery(Select).map {
      queryResult => queryResult.rows.get.map {
        item => rowToMessage(item)
      }
    }

  }

  def find(id: Long): Future[Option[Message]] = {

    pool.sendPreparedStatement(SelectOne, Array[Any](id)).map {
      queryResult =>
        queryResult.rows match {
          case Some(rows) => {
            Some(rowToMessage(rows.apply(0)))
          }
          case None => None
        }
    }

  }

  private def rowToMessage(row: RowData): Message = {
    new Message(
      id = Some(row("id").asInstanceOf[Long]),
      content = row("content").asInstanceOf[String],
      moment = row("moment").asInstanceOf[LocalDate]
    )
  }

}

{% endhighlight %}

This database calls wrapper is quite simple but shows the pattern of working with async libraries, we are
always composing on futures and returning futures as results, so you should select a framework that fits
this kind of usage or at least simplifies it. Another thing to keep in mind is that these map calls require
an execution context to be implicitly available somewhere, in this case I'm just using the execution
context that comes by default in the driver itself but you might want to provide one from your own app instead.

One way to use this at your Play app is to configure the database at your `Global` object as in:

{% highlight scala linenos %}
object Global extends GlobalSettings {

  private val databaseConfiguration = System.getenv("DATABASE_URL") match {
    case url : String => URLParser.parse(url)
    case _ => new Configuration(
      username = "postgres" ,
      database = Some("postgresql_async_app_development"),
      port = 5433
    )
  }
  private val factory = new PostgreSQLConnectionFactory( databaseConfiguration )
  private val pool = new ConnectionPool(factory, PoolConfiguration.Default)
  val messagesRepository = new MessageRepository( pool )

  override def onStop(app: Application) {
    pool.close
  }

}
{% endhighlight %}

Now, instead of using the `DatabaseConnectionHandler` object directly we use the `ConnectionPool` object that
manages a pool of connections to the database. This connection pool object implements the `Connection` trait
so you can (mostly) assume it works just like a connection, the only difference is that you should not start
transactions directly on it. If you need transactions, take a connection from the pool yourself and later
**remember to give it back to the pool when you're done**. As you can see you don't need to call connect on the
pool but you need to remember to stop it when your application is turning off. Read the class docs for more info
on it's usage.

If you're finding it weird that we're parsing the `DATABASE_URL` environment variable, this is for Heroku
support, if you drop this app on Heroku it will just work since the `URLParser` can also parse Heroku based
database URLs (yes, they're different from JDBC URLs).

## Creating the controller

And now to wrap it up, we have the controller that uses our `MessagesRepository`:

{% highlight scala linenos %}
package controllers

import play.api.mvc.{AsyncResult, Action, Controller}
import play.api.data._
import play.api.data.Forms._
import helpers.Global.messagesRepository
import com.github.mauricio.async.db.util.ExecutorServiceUtils.CachedExecutionContext
import models.Message

object Messages extends Controller {

  val messageForm = Form(
    mapping(
      "id" -> optional(longNumber),
      "content" -> text,
      "moment" -> jodaLocalDate
    )(Message.apply)(Message.unapply)
  )

  def index = Action {
    AsyncResult( messagesRepository.list.map {
      messages =>
        Ok(views.html.messages.index(messages))
    } )
  }

  def form = Action {
    Ok(views.html.messages.form(messageForm))
  }

  def edit( id : Long ) = Action {
    AsyncResult {
      messagesRepository.find(id).map {
        messageOption =>
          messageOption match {
            case Some(message) => {
              Ok( views.html.messages.form( messageForm.fill(message) ) )
            }
            case None => Ok( views.html.messages.form( messageForm ) )
          }
      }
    }
  }

  def update = Action { implicit request =>
    messageForm.bindFromRequest().fold(
      form => {
        BadRequest( views.html.messages.form(form) )
      },
      message => {
        AsyncResult {
          messagesRepository.save(message).map {
            message =>
              Redirect(routes.Messages.index())
          }
        }
      } )
  }

}
{% endhighlight %}

And now we see another pattern, as you can see from this code snippet:

{% highlight scala linenos %}
  def index = Action {
    AsyncResult( messagesRepository.list.map {
      messages =>
        Ok(views.html.messages.index(messages))
    } )
  }
{% endhighlight %}

Whenever we use the repository and get a future back, we can just tell play that this is an `AsyncResult` and
it will automatically handle processing our future and generating the response. We just compose again
on the future returned and Play will handle the rest of the work for us. And you can just push this app the
way it is to Heroku and you will have your fist async PostgreSQL backed Play app.

## Pushing to Heroku

Just setup this app on heroku with:

{% highlight bash linenos %}
heroku apps:create
{% endhighlight %}

And then:

{% highlight bash linenos %}
git push heroku master
{% endhighlight %}

Once the slug is ready, login to your psql console:

{% highlight bash linenos %}
heroku pg:psql
{% endhighlight %}

And create the `messages` table:

{% highlight sql linenos %}
CREATE TABLE messages
(
  id bigserial NOT NULL,
  content character varying(255) NOT NULL,
  moment date NOT NULL,
  CONSTRAINT bigserial_column_pkey PRIMARY KEY (id )
);
{% endhighlight %}

You should now be able to run the app and enter data correcly.

You can see my app running [here](http://postgresql-async-example.herokuapp.com/).

If you have questions, bug reports or want to help improve the library, hit me on [Github](https://github.com/mauricio)
or [Twitter](https://twitter.com/mauriciojr).