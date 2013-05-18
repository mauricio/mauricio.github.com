---
layout: post
title: mysql-async and postgresql-async 0.2.2 released!
---

And a newer version of the `postgresql-async` has finally been released and now the project includes `mysql-async`, an
async client for the MySQL database (you can read a bit more about some of the complications of building the MySQL client
at [this blog post](http://mauricio.github.io/2013/05/13/turning-a-synchronous-client-into-async-or-why-the-mysql-protocol-is-so-absurdly-complicated-to-handle.html)).

Both clients work almost the same way and they both implement the `Connection` interface so it should not be that complicated
to share implementations as long as you pay attention to the database differences. Both projects now have their own
README files, [this is the PostgreSQL one](https://github.com/mauricio/postgresql-async/blob/master/postgresql-async/README.md)
[and this is the MySQL one](https://github.com/mauricio/postgresql-async/blob/master/mysql-async/README.md).

The PostgreSQL version hasn't seen a lot of action since I was focused on getting the MySQL client to the same level of
funcionality, but there is one new feature, that is the support for `Array[Byte]` parameters for PostgreSQL 9 and above.
Support for older versions is planned for future releases. There were also many bugfixes, including contributions from
[@fwbrazil](https://github.com/fwbrasil), check the [CHANGELOG](https://github.com/mauricio/postgresql-async/blob/master/CHANGELOG.md)
for more details.

The [Play 2 + postgresql-async on Heroku](http://mauricio.github.io/2013/04/29/async-database-access-with-postgresql-play-scala-and-heroku.html)
example has also been updated with the new renamed classes, give it a go and start using async database access in your apps :)

You can add both projects to your app using the dependencies:

{% highlight scala %}
"com.github.mauricio" %% "postgresql-async" % "0.2.2"
{% endhighlight %}

Or if you are into MySQL:

{% highlight scala %}
"com.github.mauricio" %% "mysql-async" % "0.2.2"
{% endhighlight %}

If these dependencies are not showing up at Maven Central by the time you try, you can also use the snapshots from Nexus
at version `0.2.2.1-SNAPSHOT` for both drivers.

And it goes without saying that contributions, bug fixes, bug reports, benchmarks, feedback are very much welcome.