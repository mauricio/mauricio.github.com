---
layout: post
title: Why I am not using Masochism for my master-slave setups and why monkey-patching
  isn’t the only solution
tags:
- useful
---
I got a message this morning from Gregg at <a href="http://ruby5.envylabs.com/">Ruby5</a> asking why I wrote the <a href="http://github.com/mauricio/master_slave_adapter/tree">master_slave_adapter</a> plugin instead of using <a href="http://github.com/technoweenie/masochism/tree/master">Technoweenie’s Masochism</a> and I think the answer to this question deserves a little blog post (and the blog really needs some new content :P).

<!--more-->

When building the <a href="http://talkies.de/">Talkies project</a> we had to setup a master-slave environment using MySQL at the production servers. To get these things up and running I configured the replication on MySQL and set out to find a solution on Rails/ActiveRecord to handle this special need, all SELECT* statements should be sent to the slave db while all other commands should be sent to the master. The only solution available at the time was Masochism (at least it was the only one I could find).

With Rails 2.1, everything looked like we would live happily ever after, but Rails 2.2 brought a lot of changes and many of them on ActiveRecord, the main one being connection pooling and we upgraded. The production server, that wasn’t really live yet, broke badly, the new connection pooling code made the application crazy and the slave was receiving UPDATE* and INSERT* calls ( <a href="http://github.com/technoweenie/masochism/blob/cccfa41154f28953944f063c9682a4a05308e861/lib/active_reload/connection_proxy.rb">this was the code at the moment</a> ).

With this new issue showing up I set out to find a solution, the first thing was to hack the plugin itself (as github had no “issues” thing at the moment). Trying it out I couldn’t really find a simple fix and wasn’t really happy with the way the plugin worked, looked a lot like a hack when a hack wasn’t really needed, so I started to write my own solution.

The first requirement was that it should perform no black magic at all, we were burned more than once during the project by plugins that were too clever and relied heavily on monkey-patching, so my solution had to be really straightforward and do as little clever things as possible.

But hey, active_record needs a database adapter, so why not just build a fake database adapter that forwarded the work to a master or slave connection depending on the method called? This way I would never need to hack ActiveRecord, as the thing would just be a common database adapter, like all the others and the plugin would survive to Rails upgrades with little or no changes. And that’s exactly what I did, an ActiveRecord database adapter who’s job is to route method calls to a real master or slave connection.

Why was it an improvement?

By relying on the ActiveRecord database adapter contract I had no need to monkey-patch Rails itself, it would just work, even if Rails or ActiveRecord got upgraded, the only thing that would make me change the plugin was if the database adapter contract got changed and this isn’t really something that changes a lot.

And if there’s one thing that’s burning a lot of people using plugins and Rails itself is clever code and too much monkey-patching. When you’re building a solution that’s going to be “inserted” inside someone else’s codebase that you don’t even know how it’s going to look like, you better try to avoid changing too many things or breaking well known contracts, you might end up with bugs that are hard to discover and kill. And they’ll surely make you waste a lot of your time.

Monkey-patching and class-redefinition are some of the coolest features of Ruby as a language, but they should be used with care and are better avoided if possible.
