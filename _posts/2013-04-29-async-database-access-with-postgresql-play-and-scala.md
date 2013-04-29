---
layout: post
title: Async database access with PostgreSQL, Play and Scala
---

Last year I felt I wanted to contribute in some way to the Scala community. Since I didn't think I was smart
enought to work on the main libraries or compiler, I started to look for something that I could build and
would benefit me and the community in general. I started looking around and noticed that there weren't async
drivers for the good old relational databases. If you're fancy and you're using one of the new NoSQL ones,
you are most likely covered, but if you still rely on databases like PostgreSQL (like I do at my daily job),
 you have to rely on the official (and blocking) PostgreSQL JDBC driver and so the
[postgresql-async project](https://github.com/mauricio/postgresql-netty) was born.

I started looking at what people did in the NodeJS community like [node-postgres](https://github.com/brianc/node-postgres)
and I noticed you don't really need the full JDBC implementation for a usable database driver, as long as you
can execute statements and get something back, you probably have all you need so this was the goal. Build something
that would allow you to execute queries and get results back.

Let's see some sample usage:

{% highlight scala linenos %}
import com.github.mauricio.async.db.postgresql.DatabaseConnectionHandler
import com.github.mauricio.async.db.util.ExecutorServiceUtils.CachedExecutionContext
import com.github.mauricio.async.db.util.URLParser
import com.github.mauricio.async.db.{RowData, QueryResult, Connection}
import scala.concurrent.duration._
import scala.concurrent.{Await, Future}

object BasicExample {

  def main(args: Array[String]) {

    val configuration = URLParser.parse("jdbc:postgresql://localhost:5233/my_database?username=postgres&password=somepassword")
    val connection: Connection = new DatabaseConnectionHandler(configuration)

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

The basic usage pattern is quite simple, you