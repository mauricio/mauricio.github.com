---
layout: post
title: Summary of Working Effecivelly with Legacy Code - Part 2
tags:
- useful
---

# Chapter 2 - Working with feedback

[Part 1 is available here](/2012/07/21/summary-of-working-effectivelly-with-legacy-code-part-1.html)

This chapter starts with something that's well known to all developers, the two modes we use to make changes in a system, _Edit and Pray_ and _Cover and Modify_. With such suggestive names, you already know what they mean for real.

While unfortunate, the most common behavior in the industry is _Edit and Pray_. Whether it happens because people don't know better, were taught like this or are just being lazy at their jobs, it doesn't really matter. The most common answer you're going to get from people that work like this is that they're being careful while making their changes, as if being careful was enough to do it right. Thing is, even if you are careful, the odds are usually against the developer. He's could be in a busy environment, he could have external problems that are affecting his performance, it could be a friday afternoon right before a long weekend and all he thinks of is about this small vacation. We're all human and this is going to happen a lot, that's why this style of programming is very hard to keep for a long time.

When you're doing _Cover and Modify_ the order of the words is already a hint to what you're doing. First, you _cover_ and then you go make your changes. Think about doing a new painting on your car, the **very** first thing you will do is cover widows, tires, holes and anything that **should not** be painted. You don't trust yourself to do a perfect job, instead, you hope for the worst, cover all pieces and then you start doing it. Is it a sign that you have no idea how to paint a car? Probably not, it's a sign that you understand the risks and instead of tossing a coin you work on mitigating them, making sure you have less stuff to worry about while doing the job.

With software, it's all the same, when you do _Cover and Modify_ you're first covering the code with tests, making sure the behavior stays the same as we keep on adding changes. We usually see tests as a way to prove that the program is correct, which is fine and all, but the idea behind this is that we're adding tests to detect change, whether it's good or bad.

I had an interesting issue related to this a couple of days ago. I was building a version of a software we already have today running on Windows to run on Mac OS, while doing it, we noticed some of the libraries we were using on Windows were not available or did not work as expected on the Mac and this prompted us to look for Mac specific solutions in this case. One very important piece was a file system watcher, the Windows implementation wasn't capable of detecting files that were moved from one directory to another but the Mac solution was fully capable of handling this behavior. Thing is, the current application was already built with this in mind, so, what did we do? We wrote tests to make the behavior clear (not generating a rename when between folders) and then got the Mac implementation to do the same.

In the book, Michael defines these tests as a software [vise](http://en.wikipedia.org/wiki/Vise):

> Software Vise
> vise (n.) a clamping device, usually consisting of two jaws closed or opened by a screw or lever, used in carpentry or metalworking to hold a piece in position.
>
> When we have tests that detect changes, it is like having a vise around our code. The behavior of the code is fixed in place. When we make changes, we can know that we are changing only one piece of behavior at a time. In short, we're in control of our work.

But to be able to use these tests as a vise they have to be as efficient as one, they have to give you feedback right away when you're building your stuff instead of running in a very long build or QA process. That's when unit tests come in. Instead of having that large, often manual, test suite to run, you have a bunch of specific tests that exercise the piece of the system you're working on that run fast and can give you quick feedback if you're breaking something or not.

## Unit tests

The idea behind unit tests is that you are going to test your system's components in isolation to make sure they do what they're supposed to do by themselves. They don't guarantee that your system is going to behave correctly when all different objects are talking between themselves, but that's not their goal. Their main goal is to make sure the behavior in that most atomic unit in your system is well defined.

Unit tests have three qualities that will make them different from larger integration or acceptance tests, which are:

* **Error Localization** - The further away your test is from the source of the bug, the harder it is to figure out where it is. If you have an acceptance test that exhibits a bug you will have to check all related objects to figure out where the source is. With a unit test, that single unit is possibly already broken and it will be much simpler for you to detect it.
* **Execition time** - Since unit tests are supposed to run really fast (Michael says that a unit test that runs in 1 tenth of a second is already too slow to be called a unit test), you can run them many times and have a very small feedback loop, making sure every small change you make is validated right away instead of waiting forever to find it.
* **Coverage** - When doing large tests, it becomes much more complicated to follow all the paths your code has. To make matters worse, these large tests are also large in size so you would have to build another large test just because there is a small new path that isn't exercised yet. When you're working with unit tests it's much simpler to test this new path atomically.

Moving on, Michael defines stuff that he wouldn't call as unit tests:

> Unit tests run fast. If they don't run fast, they aren't unit tests.
> Other kinds of tests often masquerade as unit tests. A test is not a unit test if:
> 1. It talks to a database.
> 2. It communicates across a network.
> 3. It touches the file system.
> 4. You have to do special things to your environment (such as editing configuration files) to run it.
> Tests that do these aren't bad. Often they are worth the writing and you generally will write them in unit test harnesses. However, it is important to be able to separate them from true unit tests do that you can keep a set of tests that you can run fast whenever you make changes.

And in here we have a final definition of what a unit test is and isn't. While I believe it is fitting, we now have a blurry space for what are tests that I write for a single class, in isolation, that talks to a database or makes network requests? I do have to write tests for this class and I want this class to also be tested in **isolation** (at least as much isolation as possible) to make sure I can also change it and make sure the original behavior is not affected.

I think that, maybe, this definition of unit tests is somewhat too restrictive and we could broaden it to cover these cases when all your class do is access the file system or make network requests. On a system I am currently working on we have a fake web server that is booted with the tests of a class that makes requests to an HTTP service. This class is tested against a fake web server but it makes real HTTP requests against it and it is important for us because it has already found bugs on this code. So, I think this could also be defined as a unit test as I am test the class alone doing it's job (that is making HTTP requests).

## The legacy code dilemma

Now we move on to the most interesting piece of this chapter, dealing with legacy code. With the definition of legacy code from the [preface](/2012/07/21/summary-of-working-effectivelly-with-legacy-code-part-1.html), comes the hardest thing about working on legacy code:

> When we change code, we should have tests in place. To put tests in place, we often have to change code.

To be able to write tests for the legacy code we have in our hands currently, we need to start _fixing_ it, but then we will have to make sure our _fixes_ don't break it even further so we need tests. Yeah, just like that _GNU is not UNIX_ thing. One of the options you have is to use a refactoring tool, [but they're not 100% safe](http://dsc.ufcg.edu.br/~spg/saferefactor/), so there isn't a perfect solution for this.

Most of the problems you're going to have when trying to test legacy code is dependencies. Since the code was never unit tested before, it probably exhibits a long list of direct and indirect dependencies, cycles in the object model, stageful singletons and classes that do too much breaking the single responsibility principle. First thing you have to do then is to start breaking these dependencies.

For a very simple example, imagine the following class:

{% highlight ruby %}
class DocumentProcessor 

  def process(document)
	DocumentStorageService.instance.store( "#{document.id}.bin", document.file )
	if is_processable?( document )
	  DocumentProcessingService.instance.enqueue( document )
	end
  end
  
  def is_processable?( document )
    'application/pdf' == document.content_type
  end
  
end
{% endhighlight %}

This class has two direct dependencies, `DocumentProcessingService` and `DocumentStorageService`, it knows both classes directly, there isn't a way to avoid this with the current code and unit testing this code is probably going to generate some problems, as we will have to talk to a storage service (which could be a file system, database or cloud storage for files) and to a queue, again, another external service.

How can we remove these direct dependencies?

{% highlight ruby %}
class DocumentProcessor 

  def initialize( storage_service, processing_service )
    @storage_service = storage_service
    @processing_service = processing_service
  end

  def process(document)
	@storage_service.store( "#{document.id}.bin", document.file )
	if is_processable?( document )
	  @processing_service.enqueue( document )
	end
  end
  
  def is_processable?( document )
    'application/pdf' == document.content_type
  end
  
end
{% endhighlight %}

With the direct dependencies removed, we can now easily test our class as we have moved the dependency selection to someone else and not the executing class itself. While it's probably not going to be this simple to change in your legacy code, the idea is that since you can't write unit tests now, you should at least start moving the dependencies out so that you can start covering your classes as expected. Eventually, you will have to make more than simple changes like this and it is ok, once we meet the final goal that is to have unit tests around this code all the investment made in the first place is going to be paid off by a system that's easier to test and change.

Michael defines the _Legacy Code Change Algorithm_ as a five steps process:

1. Identify change points.
2. Find test points.
3. Break dependencies.
4. Write tests.
5. Make changes and refactor.

While it looks simple, once you face a large, unstructured and highly coupled codebase, you will understand that points _1_ and _2_ are very hard to come by. Figuring out where you need to change and where you need to test is going to be something that depends a lot on your codebase and how the application was built. Once you have this information, you go on removing dependencies to make the code testable, get your tests in place and in the end you will finally have trust that you're not going to destroy everything once you run this.

Even better, with tests in place, you can move on much faster and make bigger surgeries in the source code to simplify changes in the future and make it much more testable. No one said it would be easy, but you have to make an action.

# Summary
This chapter defines more stuff and starts pointing directly on how we are going to work with legacy code, showing us some hard truths and stuff that we should avoid when writing code and also the importance of having unit tests.