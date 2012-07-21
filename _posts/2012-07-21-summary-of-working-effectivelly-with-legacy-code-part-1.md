---
layout: post
title: Summary of Working Effecivelly with Legacy Code - Part 1
---

This week we started a book club at [OfficeDrop](http://www.officedrop.com/) and the first book selected was [Working Effectively with Legacy Code](https://www.amazon.com/dp/0131177052/ref=as_li_ss_til?tag=ultimaspalavr-20&camp=0&creative=0&linkCode=as4&creativeASIN=0131177052&adid=0JSFDNV881K8N57Q24FJ&) by Michael Feathers. Having read it a couple of years ago while in college, going through the chapters again is much more interesting now as at that time I didn't really understand all that he was talking about in the book. Today the lessons are definitely much more interesting as I see a lot of what he is talking about in code that I have worked with or am working on today.

Why make summaries of the book, you ask. Writing about it makes sure the concepts stick. Teaching is still the best way to learn.

# Preface

He opens the book, at the preface, defining what legacy code really means:

> Code without tests is bad code. It doesn’t matter how well written it is; it doesn’t matter how pretty or object-oriented or well-encapsulated it is. With tests, we can change the behavior of our code quickly and verifiably. Without them, we really don't know if our code is getting better or worse.

And as much as it did strike me as odd when I first read it, it makes **a lot** of sense today. Legacy code is not there just because it was written in an ancient language, without any documentation or by team members that are not in the company anymore. It becomes legacy code when no one wants to touch it and if people don't want to touch it, the most common reason is that it doesn't have any tests.

You can't have any confidence on changes you make to the software if you don't have tests as you can never be sure if your change is going to break something or not. You have no way to verity your changes other than manually testing them and the cycle of writing code, booting up the application and running manual tests is usually not very effective, you will probably waste a lot of time doing it and in the end you will just give up, leave the legacy code alone and build your functionality somewhere else. So, you ran away from the problem.

The code you are writing without tests today is legacy code already, there is no point in hiding it.

# Chapter 1 - Changing software

This chapter is mostly about defining what kinds of changes we usually do in software. He then defines them in four kinds:

1. Adding a feature
2. Fixing a bug
3. Improving the design
4. Optimizing resource usage

Adding a feature and fixing a bug are possibly the most blurry ones. As he walks around defining them, you start to notice that there is a lot of overlap when you're doing both. Sometimes, when you're adding a feature, from the customer's point of view, you're fixing a bug in fact (the bug of not having this functionality in there already) and sometimes fixing a bug from the developer's perspective is building a new feature, because the original definition is completely different than the one proposed by the _fix_.

What we're doing in both cases could be much more well defined if we used behavior instead of adding features or fixing bugs. When we're doing any of them we're adding new behavior and/or changing the existing behavior of the system. In another quote from the book:

> Behavior is the most important thing about software. It is what users depend on. Users like it when we add behavior (provided it is what they really wanted) but if we change or remove behavior they depend on (introduce bugs), they stop trusting us.

The other two kinds of change will not alter behavior, they will touch on different qualities of our software. Improving the design will usually be changing the code structure, how classes relate to each other, how they are coupled together to perform the behavior we expect. The most common case of design improvement is by applying the refactorings to your code, this way you do change the structure but maintaining the same behavior. 

On optimizing resource usage, instead of changing the _externally perceived_ behavior you change the internal behavior to use less of a resource to make the code go faster, use less memory or anything like that. So, while you're possibly not changing the output you will most likely change the code internally in a way that will change how it does it's job.

With this defined, we end up noticing that most of what we want to do when changing software is **preserving behavior**. Whenever you make a change to your code, you usually want to make sure the old code is not going to break and all the other funcionalities are not going to be affected by this specific change you're making (whether it's supposed to add or change any behavior or not).

And this is where the real challenge is, making sure the changes you're making aren't going to ripple through the rest of the application breaking or changing behavior that is unrelated to what you're doing. There are many ways teams deal with this, from declaring **"if it isn't broken, don't touch it"** or just by being cautious. _Well, if I pay a lot of attention to what I'm doing here, I'm not going to break anything, am I?_ And people are still trying really hard to run away and ignore the problem that they are facing instead of just going there and doing something about it.

# Conclusion
Preface and first chapter have already started with some interesting ideas, laying the groundwork for what comes next. And now I feel I should probably go back and revisit more books from college since they will probably be much more useful today that they were at that time.

Stay tuned for the next ones :)