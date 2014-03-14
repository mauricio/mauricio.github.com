---
layout: post
title: The "don't depend on a small gem" fallacy
subtitle: unless you're removing code, doesn't matter who wrote it
keywords: ruby, rubygems, reuse, libraries, frameworks
tags:
- ruby
- useful
---

There's this thing around the Ruby community (it might be at other communities as well, I don't know) that you should not depend on __small__ gems. If a gem is less than a couple hundred lines of code, you should write it yourself, because, you know, you will have to maintain it.

It isn't worth it to have a small gem in your codebase because when you upgrade your other dependencies, it might break, the current maintainer might disapear or just stop keeping the gem up to date with the newer Ruby, Rails and other dependencies it might have. And once a gem becomes unmaintained it's a burden on you and your team to handle it because no one will be able to fix that code anymore.

If you're talking to people old enough in the Ruby community, they might even invoke the good old [Jamis Buck](http://weblog.jamisbuck.org/2007/2/21/review-build-your-own-ruby-on-rails-web-applications) who wrote the following when reviewing a Rails 1.2 book (yeah, I'm old as well):

> It shows how to implement a basic user authentication system without resorting to plugins! Far, far too many newcomers to Rails jump on the user-auth plugin bandwagon, which leads to cargo-culting. My advice is: never use a plugin you would not be able to write yourself.

This last piece, __never use a plugin you would not be able to write yourself__, seems to have been burned into many people's minds. Whenever they see a small gem, they'll think (wrongly, that's not what that phrase meant):

> Ah, I don't need that, I can write that in a couple minutes and I won't have to depend on that gem anymore, it isn't worth it.

Now, let me ask you something, __what__ is the difference between that small gem code and __your__ code?

Other than the usual [not-invented-here syndrome](http://en.wikipedia.org/wiki/Not_invented_here), your code is as much a liability as other people's code. It doesn't matter who wrote it, you, your neighbour, that crazy brazilian guy who lives by the beach (me, by the way). When your application depends on it, it __becomes part of the application itself__.

Worse, if it's just a couple hundred lines of code, what kind of trouble are you having trying to understand it? Is there actually an issue or are you just trying to write code for the sake of writing code?

Unless you're __removing__ code completely, changing from someone else's code to your code (that will be someone else's code when you leave the project or job) is changing from 0 to zero. The liability is still there, the code is still there, the only difference is that if it's out there it might still have the luck of being maintained by someone else other than you. Your private code inside your private repo will __only__ be ever maintained by you and your team, there's no chance someone from the outside will help with it at all.

As important as understanding when to write code is understanding how to read and reuse code. A couple weeks ago we decided to upgrade [mongoid](https://github.com/mongoid/mongoid) from our old and venerable 2.x to 3.x so we could use the latest replica set related features. While doing this, one of our dependencies, [mongoid-sequence](https://github.com/cblock/mongoid-sequence), had to be upgraded as well and this upgrade caused issues due to a change in the way the sequence name was generated. 

We got this in QA and I could, instead of fixing the gem itself, rewrite the code for it. The gem is dead for many years now, the code we were using was a fork of the original repo already and it's just a couple lines of code, it wouldn't take long for me to rewrite it and maintain the same old behavior. But as simple as it would be to rewrite it, it was __much simpler__ to read it, understand what it was doing, what was causing the bug and fix it right there in the first place and [that's what I did](https://github.com/TheNeatCompany/mongoid-sequence) (I'm feeling bad I didn't send a pull request for them now :( ).

Rewriting it, other than taking my time that could be better used working on other important stuff, wouldn't win us anything. The code was simple, direct and the issue that was happening was clear. Once I knew what was the bug, I fixed it, updated and included tests for the case and moved on. There was no need for me to waste more time into rewriting this if I would end up with something that did the same thing with a slightly different codebase.

I even had a case of this for myself. Many years ago, I wrote a Rails plugin (do people still know what Rails plugins were?) that allowed you to have a master and a slave connection to your database. I wrote it because we were migrating from Rails 1.x to 2.x and it was all in flux, the APIs were still changing and connection pooling had just arrived to `ActiveRecord`. I could have contributed this to [masochism](https://github.com/technoweenie/masochism) but had no idea if it would be accepted (it probably would, but that's water under the bridge now) or how much code it would take since [I was using a completely different approach for it]({% post_url 2009-08-24-why-i-am-not-using-masochism-for-my-master-slave-setups-and-why-monkey-patching-is-not-the-only-solution %}) so [I just rolled my own solution](https://github.com/mauricio/master_slave_adapter).

If you look at it, there's isn't much code there, you could definitely rewrite it at your own will and make it do whatever you would want it to do, but people decided it would be simpler just [to fork and work on top of it](https://github.com/soundcloud/master_slave_adapter). If you run blame on this SoundCloud fork, it's unlikely you'll find any lines written by me, they have changed, fixed and upgrated it to their own needs and __this is actually awesome__. They have eventually moved out of my code and now it's their own thing, but this wasn't a single handed __let's rewrite all the things__ decision, it was a natural evolution of the codebase just like your own apps evolve.

So, next time someone comes in and says __let's rewrite this gem because it's small/dead/simple__ ask them back:

> Who maintains the code now? Who will maintain it in the future? 

If it's still you, there's hardly a reason to do it.

Liked this? [Upvote on Hacker News](https://news.ycombinator.com/item?id=7396800)