---
layout: post
title: Your brain on thinking and learning
subtitle: how understanding how your mind works can help you learn effectively
keywords: learning, education, brain, thinking, coursera
tags:
- useful
---

*This is part 1 of a three parts assignment for the [Learning how to learn course on Coursera](https://www.coursera.org/course/learning)*. Also check [Part 2 - Chunking concepts to solidify and compress topics]({% post_url 2015-01-22-chunking-concepts-to-solidify-and-compress-topics %}) and [Part 3 - Fighting procrastination]({% post_url 2015-01-26-fighting-procrastination%}).

Learning, specially science and math topics, usually ranges from the incredible feeling of understanding to the baffling feeling of _I have no idea what I am doing here_. While the first feeling is amazing, what gets burned in our brains is the feeling of powerlessness when we aren't able to understand a specific subject.

I remember that back in college I had this profound difficulty of understanding what a *C pointer* was when we learned C and data structures during our second semester. I couldn't wrap my head around the idea of that thing that points to another thing in memory, it was all to fuzzy, abstract. Still, while I didn't actually understand the concept, I made my way through classes and ended up moving forward.

Coming from high school where I had very little trouble understanding the concepts, this college experience was a bad start. How could I be having so much trouble to understand these topics now if I had always been able to cruise through classes before? Worse, a lot of people in my class weren't having these issues and had already grokked the concept. Did I make a bad decision going for a programming degree? Was this thing not for me?

Once we went off for winter break (June/July down here at the southern hemisphere) I decided to use the time off to better prepare myself for the new topics we would be learning. At the third semester we would start object oriented programming using Java, I saw [Deitel's Java How to Program](http://www.amazon.com/Java-How-Program-4th-Edition/dp/0130341517) at the local library and bought it. Every day I would read a bit, do the exercises and, well, enjoy my vacation. One of these days, a bit after I had learned about references in Java, the *C pointers* thing clicked.

It was one of those _AHA!_ moments out of nowhere, were all the pieces of the puzzle fell in place and the concept finally solidified in my mind. I had finally figured out what all those stuff was about and why they were there. I jumped back to *Turbo C* (yes, this was 2003 I guess) and redid the binary trees and linked lists implementations. Now, instead of just repeating what I saw from the samples provided by the teacher, I actually knew what the code I was writing was doing.

It wasn't the last time I felt like that in college (this sense of feeling dumb and failing are important parts of learning, no pain, no gain), but it was the moment I finally decided that this programming thing was for me. I wasn't *dumb* and incapable of learning how to program, as I had considered before, I just needed more effort to wrap my head around all the abstract concepts that were being presented there.

It would take me years to understand how that actually happened.

# Focused and diffuse mode thinking

Scientists nowadays believe our brain functions using two different networks, the _highly attentive states_ and the _resting state_ networks. We could call these the focused and the diffuse modes of thinking, respectively.

You enter the focused mode when you focus your brain into an specific problem or activity. When I was reading through Deitel's book, I was exercising the focused mode, intentionally pushing the information in there into my brain by reading and doing the exercises.

The diffuse mode happens when you are not specifically focusing on anything, when you let your mind drift away and leave it to itself. When I was riding the bike, walking, doing chores, taking a bus to watch a movie or just not doing anything at home my mind would be in diffuse mode (come on, I was a student on vacation, of course there were times of doing nothing).

The moment _C pointers_ clicked for me, I was in diffuse mode, my mind was wandering and connecting the ideas I had learned before while focused and it happened to finally connect the dots to make me understand it. Connecting ideas that are far away from one another or that you didn't think were connected before is one of the main goals of the diffuse mode, the brain starts making these connections and while not everything is useful, many times you will create or understand something new out of this. If you're a programmer, you most likely woke up in the wee hours with a solution for a problem you had during your day and scrambled to write it somewhere a couple times, this was your diffuse thinking doing it's work while you were asleep.

When you are in focused mode, you are working with a small set of information, you're reading a book, watching a lecture or listening to a podcast. The information in there is usually focused on a single specific subject, and this is great. You don't want to be watching a lecture that goes from Haskell to ancient aliens and ends up in rocket science, it would be really hard to understand any of it.

This focus also means your mind is mostly thinking on this specific subject alone and not trying to connect it to stuff that is not directly related to it. This leads to problems in itself as the [Einstellung effect](http://en.wikipedia.org/wiki/Einstellung_effect) were you are so focused on solving a problem in a specific way, you fail to see there are many other ways to solve it. When all you think about is hammers, every problem will look like a nail.

I did suffer from this not that long ago, when I had a project built for Windows that we wanted to see if it could be run on Linux. My first instinct was _let's get this to build on Linux_ and I did start down this path, verifying which pieces would build, which wouldn't and what we would have to make them actually build. It was definitely going to be a considerable effort but I just couldn't think of something else.

Thankfully, [my boss](https://twitter.com/PhillipLeslie) came in with another idea, what if we tried to run this over [Wine](https://www.winehq.org/)?

Guess what?

It did work. While we still want to eventually move everything to also compile on Linux, having the system running on Wine with very little effort was an huge progress (compared to the _compiling on Linux_ project).

And this is when the diffuse mode shows it's importance.

![I don't always fall, but when I do, I define gravity]({{ site.url }}/images/apple-gravity-small.jpg#img-thumbnail) When your mind is drifting in diffuse mode, it is functioning in a big picture way, it's not focusing directly at the specificities of a problem, but how it might relate to the other chunks of information you already have in your mind. Think about [Newton's apple incident (yes, it might not be true)](http://en.wikipedia.org/wiki/Isaac_Newton#Apple_incident), Voltaire said:

> Sir Isaac Newton walking in his gardens, had the first thought of his system of gravitation, upon seeing an apple falling from a tree.

He was _walking in his gardens_ when the thought reached him. Magic, right?

Not quite. Newton had been thinking about this terrestrial gravity thing for a while already and he had a large body of knowledge in physics and the forces in the universe, which he acquired through focused and diffuse mode thinking before. Maybe all he needed this small glimpse of creativity (yes, science and math also require creativity) to connect the many concepts he had in mind all the time.

He needed to have this big picture view of the ideas to connect them, but he first needed to pump these ideas into his mind using the focused mode. The diffuse mode can only connect information that is already available in your brain, it can't magically produce knowledge you never had. You'll never _get_ calculus in some magic moment if you never actually try to understand and study limits, derivatives and integrals, the information is just not there to be connected to anything.

# Take it easy

One of the major mistakes we make when studying is *studying too hard*. You find a hard problem you can't solve at that moment, you keep banging your head against the wall trying to figure out the solution, but it never comes. Then you go to sleep, for a walk or have a shower and the solution hits you.

This is not an accident. You were in focused mode all the time trying to solve the problem but the actual solution was somewhere you weren't connecting in focused mode, people will usually say you were _thinking inside the box_. The actual solution required you to _think outside the box_ but, unfortunately, you can't consciously do that.

When you find a hard problem you can't solve after a long stretch using your focused thinking, it might be the sign you need to leave it be for a while so your mind can try and fix it in the background. To do that you need to let the diffuse mode kick in and some of the best ways to do that are:

* Sleep on it - this is the most common and powerful way of doing it. Famous creatives like Thomas Edison and Salvador Dali used to sit in a lounge chair holding an object in their hand so it fell and woke them up when they started to drift away, this was just enough time to let the diffuse mode to kick in and connect their ideas;
* Go out for a walk, running, swimming or weight lifting - many writers like Jane Austen and Charles Dickens used to go for a walk to get a creativity boost;
* Have a shower;
* Meditate;
* Listen to music;
* Talk to others;

Anything that takes your mind away from the problem at hand and doesn't send you into focused mode again will do, really. The main takeaway here is that forcing yourself to solve a problem when the connections aren't really there is unlikely going to get you somewhere.

Worse, research has shown that we learn much more by spaced repetition (when you study something now and only study or practice again a day or more later) than by trying to repeat the same study or exercises one after the other. Your mind needs to rest so it can make connections and staying on focused mode all the time going over and over the same information won't really help you much at it.

To learn effectively, you need to be able to switch to both modes. You need to push the ideas into your brain by using the focused mode but you also need to let it connect with the other concepts you already have in your mind, specially when solving problems, so you can really build upon what you're learning. Balancing these modes is the key to waste as little time as possible when learning new concepts and solving problems.

# References

* [Learning how to learn course on Coursera](https://www.coursera.org/course/learning)
* [A Mind For Numbers: How to Excel at Math and Science (Even If You Flunked Algebra)](http://www.amazon.com/gp/product/039916524X/ref=as_li_tl?ie=UTF8&camp=1789&creative=390957&creativeASIN=039916524X&linkCode=as2&tag=ultimaspalavr-20&linkId=4RRWNFSX2EHUV4LT) by [Barbara Oakley](http://www.barbaraoakley.com/)
* [Brain Facts](http://www.brainfacts.org/)
