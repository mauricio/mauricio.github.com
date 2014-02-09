---
layout: post
title: Using foreman and environment variables to run your apps in development
subtitle: or why you should stop installing stuff as services in your machine
---

If you're building Rails apps you probably found yourself installing many external
dependencies to run it. A database, a full text search engine, an in memory
cache, background worker processes and many other tools that run as separate processes
in your machine. If it's a mac, you probably used [homebrew](http://brew.sh/) or
[MacPorts](http://www.macports.org/) to install these dependencies and at the end
you did something like:

    ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents

To install it as a service that runs when your machine starts.

But think about it for a bit. You're not actually running this all the time. 
If you're maintaining a gem that depends on a tool like that you might not even 
really need it for anything other than running your test suite, why should you 
have it running all the time like that?

Well, you don't!

That's where [foreman](http://ddollar.github.io/foreman/) comes into action. Foreman
is:

> a manager for Procfile-based applications. Its aim is to abstract away the details of the Procfile format, and allow you to either run your application directly or export it to some other process management format.

And what is a Procfile-based application? It's an application that has a `Procfile`
with instructions to start various processes it needs to run correctly. Here's how 
a `Procfile` might look like:

    rails: bundle exec rails s
    postgres: postgres -D /Users/mauricio/databases/postgresql
    elasticsearch: elasticsearch -f

It's a list of `name: command-to-be-run` for the dependencies you have. In this 
case we have the rails app, a PostgreSQL database and then elasticsearch. You could
have any other process you depend on running from here and never again install
anything to run as a service in your machine.

## Starting out with the database

Now that you're not installing stuff as services anymore, you can go a step further
and have isolated configurations for them as well. Let's start with a simple Rails
app:

    rails new foreman-example -T -d postgresql

I'm going to assume you're using `homebrew`, if you're not, just use the command
for the package manager you're using:

    brew install postgresql

Once it's is installed, to go the Rails app directory and run:

    pg_ctl init -D vendor/postgresql

This creates a full PostgreSQL database (config files and data files) inside
the `vendor/postgresql` directory (you could even include the db version at 
the directory name since PG is well known for changing the DB format rather
frequently). By default, PG allows access to anyone locally, if you would like
to fine tune the access control, check `vendor/postgresql/pg_hba.conf` and 
update the configuration as needed. Remember, this is a full PosgreSQL install,
you can change anything here and it will be visible only this app.

First service ready, let's create our `Procfile`, at the root
of the Rails app directory create a file called `Procfile` with the following
content:

    postgresql: postgres -D vendor/postgresql

## Redis and a master slave-setup

Now we need some in memory cache, let's get Redis for this app:

    brew install redis

Redis is even simpler than PG, you just have to reference it's config file, 
and override the keys you need to change. The file is usually at `/usr/local/etc/redis.conf`, 
if it isn't run `brew info redis` and check where it is. Let's prepare the
redis folder at our app:

    mkdir -p vendor/redis/db

Now let's create our `vendor/redis/redis/redis.conf` file:

    loglevel notice
    logfile ""
    dir vendor/redis/db/

This guarantees you're not writing to other places for this specific redis-server
instance. Everything else assumes the defaults, [you can see the defaults here](http://download.redis.io/redis-stable/redis.conf).

Now let's update our `Procfile`:

    postgresql: postgres -D vendor/postgresql
    redis: redis-server vendor/redis/redis.conf

Since we're at it, why don't we also configure a redis slave? Our app in production
might need to send reads to a slave redis and we can just get our config to do 
the same here, can't we? Let's create a separate folder:

    mkdir -p vendor/redis-slave/db

And here's the `vendor/redis-slave/redis.conf` file:

    loglevel notice
    logfile ""
    dir vendor/redis-slave/db/
    slaveof localhost 6379
    port 6380

This instructs this redis slave to connect to the master that will be running
at the default port and bind itself at port `6380`.

Here's our `Procfile` updated again:

    postgresql: postgres -D vendor/postgresql
    redis: redis-server vendor/redis/redis.conf
    redis-slave: redis-server vendor/redis-slave/redis.conf
    rails: bundle exec rails s

Now we have PG, redis, a redis slave and the Rails webapp process running. Can
we do more? Of course, we could include Nginx, another database, anything else
you might want to do here and they will all be booted when you type this at the
directory where the `Procfile` is:

    foreman start

Given you will be writing this a lot, you should probably include an alias at your
shell profile for this command, I did:

    alias fs="foreman start"

So it's just `fs` and everything is running.

Remember to include the `vendor/redis` and `vendor/postgresql` to your `.gitignore`,
you don't want to push these folders to all your colleagues. And I prefer not
to force my own `Profile` on the whole team as well, it's simpler to have a 
`Procfile-example` file at your repo and let people decide to use it at their own
will.

## Isolating the configuration

But we're not done yet, there's yet another trick at your disposal when using 
`foreman`, the `.env` files. If you've heard about [The 12 factor app](http://12factor.net/)
you probably know there are many uses to environment variables, what you might not 
know is that there are better ways than to declare all environment variables for 
all apps and gems that you maintain than at your shell's profile script. 

With `foreman` you can use `.env` files to declare the environment variables 
for your app (and it's dependencies) and maintain them isolated from the rest 
of your environment. So, if you're using the `aws-sdk` gem, your `.env` file
would look like:

    AWS_ACCESS_KEY_ID=this-is-some-access-key
    AWS_SECRET_ACCESS_KEY=this-is-some-secret
    AWS_REGION=us-west-2

And `foreman` automatically loads the `.env` file that is at the same directory
as your `Procfile`. This way you can make all environment specific configuration
for your app to live at this `.env` file and let every developer set their own
specific configurations here. All variables declared here will be available for
all processes started by `foreman` as environment variables.

## Use it everywhere

And while I used a Rails app for this example, `foreman` doesn't care about what
is being started. You can run anything that can be called from the command line
and run in the foreground, so you could possibly use it to run the dependencies
for your Java, Ruby, Go, Python or any other language. It's an awesome tool to 
have under your toolbelt wherever you go.

So, stop installing stuff as services and use `foreman` instead.

Foreman offers a bunch of other cool features like running many instances of
the same process at the same time, setting automatic values for ports to bind and 
it also exports your `Procfile` to many other formats (like Ubuntu's upstart), so 
it isn't just for development, you can actually use it at your production environment
as well. Once you're happy with your `Procfile`'s, you should go to the website 
and dig deeper into what else it can do to help you out.

The source code for this example [is here](https://github.com/mauricio/foreman-example).