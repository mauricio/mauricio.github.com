---
layout: post
title: Scala, Futures, Promises, Nett
---

The title pretty much says it all, this is the first piece on a series of posts about learning Scala by using [Netty](http://netty.io/) to build a [redis](http://redis.io/) clone. The goal is not to build a fully functional and compatible redis server, but to get you up and running in a small Scala app and at the same time present some useful knowledge of Netty and network programming in general, instead of just showing a collection of language features with empty examples.

To follow this tutorial you'll need an IDE or editor with Scala support, I prefer to use [IntelliJ](http://www.jetbrains.com/idea/), but the tutorial includes setup instructions to also setup the app using [Eclipse](http://www.eclipse.org/). And if you're the editor type of guy, the project will use [SBT](http://www.scala-sbt.org/) for dependency and project management, so you can just use the command line and your preffered text editor.

**Setup**

First, you need to create the initial project folders:

{% highlight bash %}
mdkir scaledis
cd scaledis
mkdir -p src/main/scala && mkdir -p src/main/resources && mkdir -p src/test/scala && mkdir src/test/resources && mkdir project
{% endhighlight %}

With the directories structure created, create a `build.sbt` file at the project folder with the following content:

{% highlight scala %}
name := "scaledis"

version := "0.0.1-SNAPSHOT"

scalaVersion := "2.10.2"

libraryDependencies += "org.specs2" % "specs2_2.10" % "2.2"

libraryDependencies += "io.netty" % "netty-all" % "4.0.8.Final"

libraryDependencies += "ch.qos.logback" % "logback-classic" % "1.0.13"
{% endhighlight %}

This `build.sbt` file is your project's configuration. It declares the project name, version, Scala version required and the dependencies. Unless
