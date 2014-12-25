---
layout: post
title: Technologies I'll be learning in 2015
subtitle: a futurology exercise
keywords: statistics, machine learning, rust, systems programming, distributed systems, cloud
tags:
- useful
---

I don't usually plan years in advance or try to predict what I'm going to learn as work and life priorities change over time, but my goal of building a strong statistics background over 2014 has definitely worked out exactly because I decided to focus on doing it instead of trying to do a lot of different unrelated stuff throughout the year.

With 2015 right at the door, I think it's time to define what kind of stuff I will be focusing on to keep up the pace.

## Distributed systems (or, if you prefer buzzwords, cloud computing)

As the systems grow, more and more of my work involves scaling, integrating and making sure disparate services distributed among many machines stay up and responsive. Unfortunately, most of my distributed systems knowledge has been acquired in the trenches and finding good introductory material to the field isn't easy.

The goal is to cover most of the topics [summarized here](http://the-paper-trail.org/blog/distributed-systems-theory-for-the-distributed-systems-engineer/) and then start going through the actual papers in the field. I've already finished [Distributed systems for fun and profit by ](http://book.mixu.net/distsys/) by [Mikito Takada](https://twitter.com/mikitotakada) and will continue going down the list soon. There is also a [Coursera specialization on Cloud Computing by the University of Illinois at Urbana-Champaign](https://www.coursera.org/specialization/cloudcomputing/19) that definitely looks promising, gonna enroll and see how it works out. There is also a [collection of lectures from Eidgenössische Technische Hochschule Zürich](http://dcg.ethz.ch/lectures/podc_allstars/) on many different topics about distributed systems.

While gaining experience in the trenches is amazing, understanding the theory, algorithms and options available in the field are also important when making decisions about using the various different systems available, as it can be seen at the [current discussion about tools on service discovery ](https://www.knewton.com/tech/blog/2014/12/eureka-shouldnt-use-zookeeper-service-discovery/). It's important to make informed decisions and to be able to do that we must understand how distributed systems work.

## Machine learning and even more statistics

My main reason to [dig deeper into statistics this year](http://mauricio.github.io/2014/10/01/statistics-is-fun.html) was to be able to understand what is going on at the machine learning universe. While it would have been easy to start copying algorithms and running them on data sets and call it all machine learning, I lacked the basic statistics background to understand what was actually going on with those algorithms.

Why did they work? How did they work?

Most of the courses and books on machine learning I found were about writing algorithms and it definitely felt like I was missing something not understanding the statistics that was actually behind most of them. Now that I've been able to build this backbone, I'm going back to the machine learning books and courses.

But this doesn't mean my statistics days are over, I had to pause [the Data Science specialization](https://www.coursera.org/specialization/jhudatascience/1) right in the middle because I wanted to take the [Introduction to Data Science](https://www.coursera.org/course/datasci) and [Data Analysis and Statistical Inference](https://www.coursera.org/course/statistics) courses (and both were amazing), so now it's time to circle back and finish the last courses at the specialization and do the capstone project.

My machine learning days will have to live side by side with my continuing statistics education.

The planned resources so far:

* [Machine Learning course on Coursera](https://www.coursera.org/course/ml)
* [Machine Learning: The Art and Science of Algorithms that Make Sense of Data](http://www.amazon.com/Machine-Learning-Science-Algorithms-Sense/dp/1107422221/ref=pd_cp_b_0)
* [Real world machine learning](http://www.manning.com/brink/)
* [Taming text](http://www.manning.com/ingersoll/)

## Rust and systems programming

This year I had a new foray into `C/C++` development and while I still don't have considerable experience with these system level languages, it didn't feel like I would like to devote my study time to them. The tooling feels awkward, `C++` as a language seems to give me too much power for no reason (and yes, I want to be constrained and protected from spurious crashes if possible) and it they didn't _click_ to me.

But this doesn't mean I'd never do systems programming. Now that [Rust](http://www.rust-lang.org/) is about to reach it's *1.0* release with a more consistent syntax and standard library, it is definitely time to get serious about it.

The language offers a systems programming environment while still retaining and guaranteeing a lot of the safety you only get at interpreted languages nowadays (or languages that compile to intermediary bytecodes and run on VMs like Java), has a nice functional feel (right from the [ML family](http://en.wikipedia.org/wiki/ML_%28programming_language%29), which I love by the way) and offers a simpler way to do manual memory management with it's borrowing and boxing ideas.

The first goal is to build a functional *memcached* clone. Given this requires using doing threading, data structures, networking and a lot of memory management, it's definitely going to be a nice tour around the language. Eventually, as the distributed systems education progresses, this *memcached* clone will become a [CRDTs server](http://en.wikipedia.org/wiki/Conflict-free_replicated_data_type) so I can get some of this distributed systems knowledge out there. Given there aren't that many `CRDT` server solutions out there, this might definitely become an actual and useful project in the long run.

## Is this doable at all?

I've no idea. But having a clearly laid plan for that to study at 2014 did show me that focus was an important part of actually learning a topic. For many years I would be picking up stuff randomly, reading many different chapters in different books on different topics and, as you can imagine, very little of this was actually useful in the long run.

Even if I can't do all this, I'm sure focusing on these topics and not on everything else that shows up at my twitter feed or hacker news is definitely a better bet at gaining new knowledge.

Do you have any other recommendations for these fields? [Hit me on twitter!](https://twitter.com/mauriciojr)

May 2015 be an awesome year for all of us :)
