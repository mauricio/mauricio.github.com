---
layout: post
title: Asynchronous email deliveries using Resque and resque_action_mailer_backend
tags:
- outdated
---

If you have ever sent emails using ActionMailer during a user request you probably noticed that if the email sending fails or takes too long your user might not be really happy with the speed of your application. Making the email sending process an asynchronous one is usually the simplest solution for this problem and there are plenty of tools to do that like ar_mailer, that stores emails in your database and then uses a specific daemon to send them.

<!--more-->

<a href="http://seattlerb.rubyforge.org/ar_mailer/">ar_mailer</a> and other solutions are quite enough for most of your problems but what if you’re already using Resque to run your asynchronous jobs? Why bother using yet another daemon to do the email sending jobs with all the hassle of managing if you can use your current Resque setup to do it?

With this in mind I sat a bit and wrote this simple gem that lets you do exactly that, send your emails asynchronously using a Resque worker and without changing a single line of your email sending code. Following the same philosophy of ar_mailer, the resque_action_mailer_backend doesn’t require you to call fancy methods on your mailers, you just keep them as they are now and instead of changing them you just change the delivery method to :resque, like this (in a environment file, like “development.rb”):

<pre class="brush:ruby">config.action_mailer.delivery_method = :resque</pre>

The gem uses your ActionMailer::Base.smtp_settings configuration to deliver the emails, so you don’t have to change anything in there, just be sure that the SMTP credentials are correct so the worker can deliver emails without issues. The default queue name is “:headbanger_resque_mailer”, but you can change it to whatever you’d like to with this code:

<pre class="brush:ruby">Headbanger::ResqueMailer.queue = :your_email_queue</pre>

This single line of code changed will now make all your emails be queued to Resque and they’ll be sent as soon as a worker is available for it. Now you only have to tell your rails application to load the resque_action_mailer_backend gem (in your environment.rb):

<pre class="brush:ruby">config.gem &quot;resque_action_mailer_backend&quot;</pre>

You can check a some hints on using this setup at <a href="http://github.com/mauricio/resque_action_mailer_backend_example">this sample project</a>.

And you’re ready to start sending emails asynchronously using your resque workers!

Enjoy!
