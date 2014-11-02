---
layout: post
title: Statistics is fun
subtitle: and this isn't a joke
keywords: coursera, education, learning, improvement, statistics
tags:
- useful
---

Statistics, whether we notice it or not, is part of our everyday lives. Be it when we hear about inflation, unemployment rates, polls, information produced from statistical methods are everywhere and we use it often to make sense of the world and make decisions even when we don't actually understand how we ended up with those _values_.

Many years ago (ok, 10 years ago), while in college, I had this statistics class. It wasn't bad, the teacher was decent and the material, while not the best, wasn't horrible either. The main issue was that I was learning to program and, unfortunately, statistics wasn't being presented as an interesting topic that could compete with the universe of programming that was opening up for me at that time.

The information I was presented during these last 8 weeks of [Data Analysis and Statistical Inference](https://www.coursera.org/course/statistics) has been not only valuable in the sense of understanding the tools and basic concepts around machine learning, which was my initial goal, but also gave me tools to better understand the world around me.

## The Brazilian election case

Brazil has just gone over one of it's most competitive president elections of all time, with two sides fighting for every inch of the electorate and, as you can imagine, polls were abound. Before taking the class, I knew that the *margin of error* was a sign that the _actual_ value was inside the interval provided. So, if one of the candidates was with 38% of the votes with an margin of error of 2% the actual value was between 36% to 40%.

So, I knew what it meant but I had no idea how they got at that specific interval. Going through the classes I then learned that the margin of error for proportions is calculated like:

<math display="block">
  <mrow>
    <mi>ME</mi>
    <mo>=</mo>
    <mi>z*</mi>
    <mo>×</mo>
    <msqrt>
      <mfrac>
        <mrow>
          <mi>p</mi>
          <mo>×</mo>
          <mfenced open="(" close=")" separators="">
            <mi>1</mi>
            <mo>-</mo>
            <mi>p</mi>
          </mfenced>
        </mrow>
        <mi>n</mi>
      </mfrac>
    </msqrt>
  </mrow>
</math>

Where `p` is the probability your poll calculated and `n` is the number of people you interviewed and `z*` is a special value we pick to to decide how confident we are about this result, it would be _1.96_ for a 95% confidence level.

_Why is this interesting?_, you might ask, well, in the case of polls for our election here in Brazil it was pretty important because before making a poll you have to *register the poll* with the local electoral justice department *including your margin of error*.

Now look back at the `ME` formula, can you see something weird about the statement above?

You *can't* calculate the margin of error without the actual probability so we end up with a chicken and egg problem, you need the `ME` to register the poll but then you need to actually execute the poll to produce the `ME`.

What actually happens is that pollsters just include a bogus `ME` and hope their calculations will be actually close to that. And as you can imagine, many of the polls produced results that were incredibly different than the real election results.

## The One Ring to rule them all

The course emphasis on hypothesis testing and bullshit detection (professor Mine never actually says this, but that's what it is, seriously) has made me look at data and analysis under a very different light. There is a strong focus on making sure you understand what you are *saying* about the data you have and the analysis you are making so that you don't imply causation where it can't be implied and avoid extrapolating models to data they can't actually work with.

As the saying goes:

> Statistics is the art of torturing the numbers until they say what you want them to.

But if you actually understand how these statistics work, you might just be able to detect the torture and avoid being amazed by yet another bogus analysis. A solid understanding of the basics will help you to avoid [spurious correlations](http://www.tylervigen.com/) and making bad decisions based on bad data and biased analysis.

And to the amusement of my old me of 10 years ago, most of this stuff happens in programming environments nowadays, even the learning. The use of [R](http://www.r-project.org/) (both running on your own machine or through [DataCamp](https://www.datacamp.com/)) throughout the course makes the whole learning process much more interactive as you can _touch_ the data and play around with it as much as you'd like to.

Learning statistics for real has definitely had a real impact in my life and my view of the world and even if I don't actually apply this knowledge directly at work, the effects the critical thinking and evaluation tools I've been presented will.

So don't let your previous bad experiences or prejudice against statistics hold you back, there is a whole world of numbers and data to be explored out there and it keeps growing. All you have to do to tap onto these new fountains of data is understanding statistics.

Enroll and enjoy, I'm sure you'll have a blast at it as much as I had myself.

<script type="text/javascript"
  src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
</script>
