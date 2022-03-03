---
layout: post
title: Should you document your code?
keywords: documentation, architecture, design
tags:
- useful
---

Time and again, the old "well-written code does not need documentation" rears its ugly head in software circles. Like all the other silver bullets and magical thinking solutions, it ignores context and the realities of building software in the real world. While well-meaning, as good code should be straightforward to follow, it's hard to express all the decisions that led to that code directly on it, and a couple of weeks from when you wrote, none of it will make sense.

In most codebases, we have tacit and explicit knowledge. Explicit knowledge is what is documented, structured, and well defined. You don't need to ask other people on the team about it. It's already there and available for you to consume. Tacit knowledge is the general understanding people on the team have about the code instinctively. It is knowing changing some part of the project usually leads to bugs or that you shouldn't change some specific configuration because it causes it to break or misbehave in exceptional cases.

The main goal of documenting code is to turn tacit knowledge into explicit, so you and everyone else don't have to keep all this context in memory. Humans are known to be bad at memorization. We routinely misplace objects we use day-to-day, create false memories because of stories we've heard, and forget stuff. As much as you might think you're going to remember the decisions and reasoning that led to the code you're writing, you won't. So, be selfish, think about you a month from now, looking at this code and not knowing why and how it works, you won't have a great time.

## Why did I write this?

One of the most critical effects of documenting code is defining the context you wrote it. It's easy to look at code today and think _who wrote this shit_ and later running `git-blame` finding out you wrote it. *Why did I do that?*

It's likely whoever wrote the _shitty_ code you're looking at had good reasons to do so, and documenting such reasons makes them available to whoever is reading and touching it in the future. Document why the code does what it does, what was the context and reasoning to do it, so it's clear to whoever is reading it why it works the way it does so they know the requirements and expected behavior.

While going through [a transition](https://dev.to/mauriciolinhares/transitioning-projects-to-new-owners-j70) for one of our projects, I noticed code that performed health checking of other services (sending HTTP requests to verify these services are reachable) did something strange. The health checker is configured with multiple endpoints for each service. If one endpoint fails, it goes out of rotation, and traffic is sent to the other endpoints that are available (if a service has HostA, HostB, and HostC and HostA is failing, we only send traffic to HostB and HostC), but if all endpoints fall all hosts go back in the rotation.

There were no comments about why it behaved like this, so it was time to go some `git` spelunking. An incident a long time ago happened because someone made a mistake on their service configuration and added a health check that would never succeed, taking the whole service down. In response to this incident, we decided that if all endpoints for a service fail, we should assume it was just a misconfiguration and not that it is down and bring all endpoints back. This is now an obvious comment in the code that performs health checking. There is no need to dig into `git` history or go through JIRA tickets to figure out why something behaves the way it does.

You want to have the reasoning that led to the code explained, so no one needs to perform code archeology to figure out why something works the way it does. Having it clear will lead to fewer incidents and issues when people think they can change the code they see as it might look wrong, stupid, or unnecessary. Until we invent crystal balls where people can find out right away what the effects of changing code will be, it's best to say why it does what it does.

## How does it do it?

Now on to the pernicious explanation of how the code works. People will frequently say you don't need to say what it does because it is right there in front of you, but there are valid reasons for you to explain the code as it is. One is to make it easier for people to associate the how with the abstraction you're using.

Is it using a design pattern? Make it part of the name of the class/function and add in the docs that this is the X pattern. Is it using a known algorithm? Say it in the comments that it uses that specific algorithm.

This makes it much easier for whoever is writing the code to dig into it as they don't have to find out you used specific patterns or algorithms. It's right there in the comments for them to prime their expectation on what they're looking at.

## Internal use vs library code

Comments also change if you're dealing with code you're only using once, internally in a project,  or code that will be widely shared inside an organization or to the broader public. If it's just internal code, it might make sense to mainly document the reasoning and context and be done with it. If what you're working on is a library that other people on other teams will use, the requirements will change.

A great example is [Go's http package](https://pkg.go.dev/net/http). Most types are documented with *examples* on using them, like the [http.Get function](https://pkg.go.dev/net/http#example-Get). There is also a full separate package that allows you to unit test code that uses the `http` package, [httptest](https://pkg.go.dev/net/http/httptest).

So when writing libraries, you have to think both about how people are going to learn how to use them and what you can do to make the experience more straightforward. Will users need a particular way to perform unit testing? Should you provide mocks? Are there use cases that need specific setups you could simplify with a testing package? These are all issues you have to consider when writing code for other people to consume.

## Yes, you should write docs

So, yes, you should document your code. Not only for the people that will be working on it in the future once you've left your job but also for you a couple of weeks from now trying to figure out why you wrote these strange lines of code you have no memory of. The less context you have to carry with you while working, the better the experience will be.