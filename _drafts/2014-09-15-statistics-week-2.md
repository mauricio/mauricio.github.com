---
layout: post
title: Data Analysis and Statistical Inference - Week 2
keywords: coursera, statistics, R
tags:
- statistics
- coursera
- useful
---

## Random process

Random process is when we have a process where we know what could possibly happen but we don't know which one will happen exactly. This could be flipping a coin or rolling a die. We know there is a `1/2` chance of a coin flip being a head, but there is no way to say it **will** be a head.

Most of the time, when talking about probabilities, we'll be working with the form:

    P(A) = Probability of event A happening

Every probability value is a number that follows the rule below:

<script type="text/javascript"
  src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
</script>

<math display="block">
  <mrow>
    <mn>0</mn>
    <mo>&#8804;</mo>
    <mi>P(A)</mi>
    <mo>&#8804;</mo>
    <mn>1</mn>
  </mrow>
</math>

So, if you ever get a probability that's lower than 0 or more than 1, you know there's something wrong there.

There are two different interpretations for probability in statistics. The frequentist interpretation says that this number represent the proportion of times the specific outcome will happen if we try the operation an infinite number of times. For instance, if you flip a coin infinite times, the expectation is that the amount of heads and tails will be roughly the same, if it isn't you most likely don't have a fair coin.

The bayesian interpretation declares that probability is a subjective degree of belief that a given outcome will happen. This allows the probability to use external knowledge or intuition about the process to derive the probability value, even when there might not be a known random process involved.

## The law of large numbers

This law is the one that states that as you collect more occurrences of a random event, you'll see that the proportions will converge to the probability of that specific outcome. So, as it was said above, if you keep flipping a coin, the numbers of heads or tails will be roughly `1/2` each.

But we must be careful not to misinterpret this as the **gamblers fallacy** that states that if one outcome of a random event happens many times for a period it will happen less frequently in the future.

Imagine for instance a roulette, we have 38 numbers (for the American roulette) and half of them are black with the other half being red. I pick the `all blacks` option. What is the probability that a black number happens?

<math display="block">
  <mrow>
    <mfrac>
      <mrow>
        <mn>19</mn>
      </mrow>
      <mrow>
        <mn>38</mn>
      </mrow>
    </mfrac>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>2</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>

Now, let's imagine we there were 5 reds in a row (bummer, I lost FIVE times!), what is the probability that the next result is a black?

<math display="block">
  <mrow>
    <mfrac>
      <mrow>
        <mn>19</mn>
      </mrow>
      <mrow>
        <mn>38</mn>
      </mrow>
    </mfrac>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>2</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>

Wait, what? Still `1/2`?

Yes. The probability of a single event happening does not change because of previous events (unless I asked _what is the probability of 5 reds and a black in a row_). While the proportion of red and black results will eventually be of `1/2` each as we infinitely roll the roulette (assuming it isn't a biased one, be careful), this doesn't mean that the results will have to be evened out as you're observing them.

So, don't waste your money on this.

## Event types

We say two events are disjoint (or mutually exclusive) when they can't happen at the same time. For instance, when you flip a coing you can't have both head and tail at the same time, it's either one or the other. We can then declare their probabilities with the following formula:

<math display="block">
  <mrow>
    <mi>P(A and B)</mi>
    <mo>=</mo>
    <mn>0</mn>
  </mrow>
</math>

Non-disjoint events are the ones that can happen at the same time. For instance, taking a card that is both an ace and red from a deck of cards is a non-disjoint event as you could take the ace of hearts. The formula for non-disjoint events can be declared as:

<math display="block">
  <mrow>
    <mi>P(A and B)</mi>
    <mo>≠</mo>
    <mn>0</mn>
  </mrow>
</math>

Given two disjoint events, if we wanted to calculate the possibility of one or the other happening, we just have to sum both probabilities. So, given a deck of cards, if we wanted to calculate the probability of taking a `Jack` or a `3` we would do it as follows:

<math display="block">
  <mrow>
    <mi>P(Jack or 3)</mi>
    <mo>=</mo>
    <mi>P(Jack)</mi>
    <mo>+</mo>
    <mi>P(3)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(Jack or 3)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>4</mn>
      </mrow>
      <mrow>
        <mn>52</mn>
      </mrow>
    </mfrac>
    <mo>+</mo>
    <mfrac>
      <mrow>
        <mn>4</mn>
      </mrow>
      <mrow>
        <mn>52</mn>
      </mrow>
    </mfrac>
  </mrow>  
</math>  
<math display="block">
  <mrow>
    <mi>P(Jack or 3)</mi>
    <mo>≈</mo>
    <mi>0.154</mi>
  </mrow>  
</math>

Now, how do we do the same calculation for two non-disjoint events? Given two events `A` and `B`, the probability that one or the other happens is given by the following formula:

<math display="block">
  <mrow>
    <mi>P(A or B)</mi>
    <mo>=</mo>
    <mi>P(A)</mi>
    <mo>+</mo>
    <mi>P(B)</mi>
    <mo>-</mo>
    <mi>P(A and B)</mi>
  </mrow>
</math>

The only difference between this formula and the one for disjoint events is the `- P(A and B)` part. Why is it there? Because when two events are non-disjoint we have to remove the probabilities that both will happen from the sum of their original probabilities, otherwise we would be counting the probability of both happening twice.

Even better, as we said before, since the probability of `P(A and B)` when A and B are disjoint is zero, this is actually the same formula as the one we used for the disjoint case above. As it would look like this:

<math display="block">
  <mrow>
    <mi>P(A or B)</mi>
    <mo>=</mo>
    <mi>P(A)</mi>
    <mo>+</mo>
    <mi>P(B)</mi>
    <mo>-</mo>
    <mi>0</mi>
  </mrow>
</math>

We just remove the `- 0` part and leave the sum only. So there is only one formula to be remembered, it is called the _general addition rule_.

Let's work on an example now, what's the probability that we take a Jack or a red card from the deck?

<math display="block">
  <mrow>
    <mi>P(Jack or red)</mi>
    <mo>=</mo>
    <mi>P(Jack)</mi>
    <mo>+</mo>
    <mi>P(red)</mi>
    <mo>-</mo>
    <mi>P(Jack and red)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(Jack or red)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>4</mn>
      </mrow>
      <mrow>
        <mn>52</mn>
      </mrow>
    </mfrac>
    <mo>+</mo>
    <mfrac>
      <mrow>
        <mn>26</mn>
      </mrow>
      <mrow>
        <mn>52</mn>
      </mrow>
    </mfrac>
    <mo>-</mo>
    <mfrac>
      <mrow>
        <mn>2</mn>
      </mrow>
      <mrow>
        <mn>52</mn>
      </mrow>
    </mfrac>
  </mrow>  
</math>  
<math display="block">
  <mrow>
    <mi>P(Jack or red)</mi>
    <mo>≈</mo>
    <mn>0.538</mn>
  </mrow>  
</math>


## Sample space

The sample space is the collection of all outcomes of a trial. If our trial is flipping a coin once, the possible outcomes are:

    [ head, tail ]

If we're rolling a six-sided die:

    [1, 2, 3, 4, 5, 6]

If the trial is rolling a single coin twice:

    [ head, head ]
    [ tail, tail ]
    [ head, tail ]
    [ tail, head ]

## Probability distributions

A probability distribution is a sample space with the probabilities that each of the outcomes could happen. For instance, at our previous example of tossing a single coin twice, the probability distribution would be:

    [ head, head ] - 0.25
    [ tail, tail ] - 0.25
    [ head, tail ] - 0.25
    [ tail, head ] - 0.25

Given the probability of any of the events happening is the same (none of them is more or less likely to happen) the actual probability for each of them is `1/4`. And since the probability distribution must account for every single outcome, the sum of all probabilities must be 1.

## Complimentary events

Complimentary events are two mutually exclusive events whose probabilities sum to 1. For instance, when flipping a coin, the complimentary event for a `head` is the event of a `tail` as the probability of a `head` is `1/2` and the `tail` `1/2` as well and their sum is 1.

We must be careful not to mix complimentary with disjoint events. While every complimentary events are always disjoint, disjoint events are not always complimentary. For instance, when rolling a die, the event of rolling a `1` is disjoint from the event of rolling a `2` but they are not complimentary as the sum of their events is not 1:

<math display="block">
  <mrow>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>6</mn>
      </mrow>
    </mfrac>
    <mo>+</mo>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>6</mn>
      </mrow>
    </mfrac>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>3</mn>
      </mrow>
    </mfrac>
  </mrow>  
</math>

The complimentary event for rolling a `1` is rolling any one of `[2, 3, 4, 5, 6]`, which would be:

<math display="block">
  <mrow>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>6</mn>
      </mrow>
    </mfrac>
    <mo>+</mo>
    <mfrac>
      <mrow>
        <mn>5</mn>
      </mrow>
      <mrow>
        <mn>6</mn>
      </mrow>
    </mfrac>
    <mo>=</mo>
    <mn>1</mn>
  </mrow>  
</math>

Where the sum is actually `1`. So, remember, while all complimentary events are disjoint, not all disjoint events are complimentary.

## Independence and independent events

Events are said to be independent when the outcome of one does not affect the outcome of the other. Think about rolling a die, having rolled a `1` already does not provide you with any useful information about what's going to happen the next time you roll (remember the gambler's fallacy above? yeah, again).

We can define this mathematically with the following formula:

<math display="block">
  <mrow>
    <mi>P(A | B)</mi>
    <mo>=</mo>
    <mi>P(A)</mi>
  </mrow>
</math>

We can read this as:

> Given that B has happened, the probability of A happening is P(A), the original probability of A happening.

So, knowing that `B` has happened has no impact on the event of A happening, hence, these are independent events.

Given we know two events A and B are independent, the probability of A *and* B happening together is calculated with the following formula:

<math display="block">
  <mrow>
    <mi>P(A and B)</mi>
    <mo>=</mo>
    <mi>P(A)</mi>
    <mo>×</mo>
    <mi>P(B)</mi>
  </mrow>
</math>

Let's get back to our dice rolling example, if I wanted to calculate the probability of rolling a `1` and then a `2` here's what I would have:

<math display="block">
  <mrow>
    <mi>P(1 and 2)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>6</mn>
      </mrow>
    </mfrac>
    <mo>×</mo>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>6</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(1 and 2)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mn>36</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>

So, since the probability of `1` or `6` happening are independent, the probability that they will both happen is just multiplying their probabilities which produces the final probability of `1/36`.

## A small example to tie everything together

Let's look at a phase of the World Values Survey and use it to build a couple examples with the stuff we've seen so far:

> At a World Values Survey people were asked if they agree with the statement "Men should have more right to a job than women". Out of 77,882 people polled from 57 countries, 36.2% agreed with this. 13.8% of the people pulled have a university degree or higher and 3.6% fit both criteria.

Let's start by declaring the probabilities we know about already:

<math display="block">
  <mrow>
    <mi>P(agree)</mi>
    <mo>=</mo>
    <mn>0.362</mn>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(university degree)</mi>
    <mo>=</mo>
    <mn>0.138</mn>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(agree and university degree)</mi>
    <mo>=</mo>
    <mn>0.036</mn>
  </mrow>
</math>

Now that we have the survey data, let's start answering questions:

> 1 - Are agreeing with the statement and having a university degree or higher disjoint events?

To know if A and B are two disjoint events, we know the formula is as follows:

<math display="block">
  <mrow>
    <mi>P(A and B)</mi>
    <mo>=</mo>
    <mn>0</mn>
  </mrow>
</math>

And for our case we know that `P(A and B)` or `P(agree and university degree)` is not `0` then these events are not disjoint.

> 2 - Draw a Venn diagram summarizing the variables and their associated probabilities.

![Venn Diagram]({{ site.url }}/images/stats-week-2/venn.png)

Here we have a very simple Venn diagram of the probabilities that shows us both the specific independent probabilities and the _shared area_ where we find the people who both agree and have a university degree.

To figure out the independent probabilities (the ones out of the shared area) we just have to do:

<math display="block">
  <mrow>
    <mi>P(agree but no university degree)</mi>
    <mo>=</mo>
    <mi>P(agree)</mi>
    <mo>-</mo>
    <mi>P(agree and university degree)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(agree but no university degree)</mi>
    <mo>=</mo>
    <mi>0.362</mi>
    <mo>-</mo>
    <mi>0.036</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(agree but no university degree)</mi>
    <mo>=</mo>
    <mi>0.326</mi>
  </mrow>
</math>

And this gives us the value of the left circle at the Venn diagram. To calculate the value of the right one we would just do the same and reach `0.102` as the result.

> 3 - What is the probability that a randomly drawn person from the survey has a university degree or agrees with the statement about men having more right to a job than women?

This is a simple case of the general addition rule we have seen before:

<math display="block">
  <mrow>
    <mi>P(A or B)</mi>
    <mo>=</mo>
    <mi>P(A)</mi>
    <mo>+</mo>
    <mi>P(B)</mi>
    <mo>-</mo>
    <mi>P(A and B)</mi>
  </mrow>
</math>

When we input the values we already have it becomes:

<math display="block">
  <mrow>
    <mi>P(university degree or agrees)</mi>
    <mo>=</mo>
    <mi>P(university degree)</mi>
    <mo>+</mo>
    <mi>P(agrees)</mi>
    <mo>-</mo>
    <mi>P(university degree and agrees)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(university degree or agrees)</mi>
    <mo>=</mo>
    <mi>0.138</mi>
    <mo>+</mo>
    <mi>0.362</mi>
    <mo>-</mo>
    <mi>0.036</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(university degree or agrees)</mi>
    <mo>=</mo>
    <mi>0.464</mi>
  </mrow>
</math>

So, the probability of someone having a university degree or agreeing with the statement is of `46.4%`.

> 4 - What percent of the population do not have a university degree and disagree with the statement?

The part of the population that does not have a university degree and does not agree with the statement is the complement for our `P(university degree or agree)` probability so e can calculate it with:

<math display="block">
  <mrow>
    <mi>P(no degree and disagrees)</mi>
    <mo>=</mo>
    <mn>1</mn>
    <mo>-</mo>
    <mi>P(university degree or agrees)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(no degree and disagrees)</mi>
    <mo>=</mo>
    <mn>1</mn>
    <mo>-</mo>
    <mn>0.464</mn>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(no degree and disagrees)</mi>
    <mo>=</mo>
    <mn>0.536</mn>
  </mrow>
</math>

So we now know that `53.6%` of the population disagrees with the statement and do not have a university degree.

> 5 - Does it appear that the event someone agrees with the statement is independent from having a degree?

To answer that we have to go back to the formula for independent events

<math display="block">
  <mrow>
    <mi>P(A and B)</mi>
    <mo>=</mo>
    <mi>P(A)</mi>
    <mo>×</mo>
    <mi>P(B)</mi>
  </mrow>
</math>

Since we know our `P(A and B)` is `P(university degree and agrees)` (`0.036`) the result of `P(A and B)` must be equal to `0.036` for these events to be independent. Let's calculate:

<math display="block">
  <mrow>
    <mi>P(university degree and agrees)</mi>
    <mo>=</mo>
    <mi>P(university degree)</mi>
    <mo>×</mo>
    <mi>P(agrees)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mn>0.036</mn>
    <mo>=</mo>
    <mn>0.138</mn>
    <mo>×</mo>
    <mn>0.362</mn>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mn>0.036</mn>
    <mo>≠</mo>
    <mn>0.049956</mn>
  </mrow>
</math>

And given the values are different, we know these events are not independent.

> 6 - What is the probability that at least 1 in 5 randomly selected people agree with the statement?

Again we go for complement rules, this event is the complement for all 5 people disagreeing with the statement. To calculate the amount of people that disagree we simply calculate the complement for it as well:

<math display="block">
  <mrow>
    <mi>P(disagree)</mi>
    <mo>=</mo>
    <mn>1</mn>
    <mo>-</mo>
    <mi>P(agrees)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(disagree)</mi>
    <mo>=</mo>
    <mn>1</mn>
    <mo>-</mo>
    <mi>0.362</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(disagree)</mi>
    <mo>=</mo>
    <mn>0.638</mn>
  </mrow>
</math>

Now let's calculate the complement for the case where everyone disagrees, which will give us the probability of at least one person agreeing:

<math display="block">
  <mrow>
    <mi>P(at least one agrees)</mi>
    <mo>=</mo>
    <mn>1</mn>
    <mo>-</mo>
    <mfenced open="(" close=")" separators="×">
      <mi>P(disagrees)</mi>
      <mi>P(disagrees)</mi>
      <mi>P(disagrees)</mi>
      <mi>P(disagrees)</mi>
      <mi>P(disagrees)</mi>
    </mfenced>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(at least one agrees)</mi>
    <mo>=</mo>
    <mn>1</mn>
    <mo>-</mo>
    <msup>
      <mn>0.638</mn>
      <mn>5</mn>
    </msup>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(at least one agrees)</mi>
    <mo>=</mo>
    <mn>1</mn>
    <mo>-</mo>
    <mn>0.1057069</mn>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(at least one agrees)</mi>
    <mo>=</mo>
    <mn>0.8942931</mn>
  </mrow>
</math>

So, the chance that at least one person agrees with the statement out of 5 is of `89.4%`.

And here we are, all of the previously presented topics organized together at a single exercise.

## Disjoint vs independent events

It's easy to mixup disjoint and independent events as being the same thing but they're not. Let's start by redefining them, two events are disjoint when they can't happen at the same time. For instance, given our previous survey example, the event that someone agrees is disjoint from the event this same person disagrees with the survey as you can't both agree and not agree with it. This is a mutually exclusive choice.

Two events are independent when knowing the outcome of one provides no useful information about the outcome of the other. Again going back to our survey, knowing that the first randomly sampled person we picked in the streets agrees with the statement of the survey provides us no useful information about the next person we try to pick randomly in the streets as well.

We could, for instance, have disjoint events that are dependent. Imagine babies can only have blue, green or brown eyes and both eyes of the same color. Having eyes as blue, green or brown is a disjoint event as you can't have eyes that are both green and brown. Given you know a couple had a baby with blue eyes, is the probability their next baby will also have blue eyes independent of the fact they already have a baby with blue eyes?

No, because this trait is passed along by their genes. So, while the color of the eye of the second baby is a disjoint event (it can only be one color), it could be a dependent event if you had more information about the parent's genes and siblings.

So, be careful and don't mix independent and disjoint events.

## Conditional probabilities

Let's start with the study presented:

> Adolescents' understanding of social class - 48 working class and 50 upper middle class 16-years-olds

The study subjectively associates students with the social class they think they are using survey questions. This information is then compared with their actual social class based on reported measures of the student's parents occupation, education and household income.

Here's the contingency table with the results of the study:

    subjective         | working class | upper middle class | total
    ------------------ | ------------- | ------------------ | -----
    poor               | 0             | 0                  | 0
    working class      | 8             | 0                  | 8
    middle class       | 32            | 13                 | 45
    upper middle class | 8             | 37                 | 45
    upper class        | 0             | 0                  | 0
    ------------------ | ------------- | ------------------ | -----
    total              | 48            | 50                 | 98

We start by taking the marginal probabilities, first, what's the probability that a student is from the upper middle class objective position? We take the upper middle class column:


    upper middle class | total
    ------------------ | -----
    0                  | 0
    0                  | 8
    13                 | 45
    37                 | 45
    0                  | 0
    ------------------ | -----
    50                 | 98

And divide it's sum by the total of students in the study:

<math display="block">
  <mrow>
    <mi>P(objective upper middle class)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>50</mn>
        <mn>98</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(objective upper middle class)</mi>
    <mo>=</mo>
    <mn>0.5102041</mn>
  </mrow>
</math>

So, the probability of being at the `objective upper middle class` is `51%`. Given the only other option is being at the `objective working class` the probability for it is the complement of `upper middle class` that gives us the value of `49%`. We call these marginal probabilities because we have calculated them from the **margin** of the contingency table.

Now, what's the probability that a student's `subjective` and `objective` identity are both upper middle class? Let's look at the part of the table that gives us this information:

    subjective         | upper middle class
    ------------------ | ------------------
    upper middle class | 37

So, we have 37 students where they both objectively and subjectively identify as `upper middle class`, to calculate the probability of picking a random student that fits this criteria we divide 37 by the total of students in the survey:

<math display="block">
  <mrow>
    <mi>P(objective and subjective upper middle class)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>37</mn>
        <mn>98</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(objective and subjective upper middle class)</mi>
    <mo>=</mo>
    <mn>0.377551</mn>
  </mrow>
</math>

So there is a `37%` probability that you'll pick a student that's in both subjective and objective `upper middle class`. We call this a **joint** probability because it's taken from data that is at the intersection of two events of interest.

Here's a Venn diagram for these numbers:

![Objective UMC and Subjective UMC]({{ site.url }}/images/stats-week-2/subjective-objective-venn.png)

Let's go for another one, what's the probability that a student that is objectively at the working class associates himself with the upper middle class?

Let's cut the table again:

    subjective         | working class
    ------------------ | -------------
    upper middle class | 8
    ------------------ | -------------
    total              | 48

Let's build the formula for this:

<math display="block">
  <mrow>
    <mi>P(objective working class | subjective upper middle class)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mn>8</mn>
        <mn>48</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(objective working class | subjective upper middle class)</mi>
    <mo>=</mo>
    <mn>0.1666667</mn>
  </mrow>
</math>

The important thing to note here is the `|` at the probability declaration, this denotes this probability as a **conditional** probability because we know already that the students are objectively in the working class, so we don't have to consider everyone in the survey, only those that match this criteria. So, given we know that the students are objectively working class, the probability they will identify themselves as upper middle class is of `17%`.

## Bayes' Theorem

This use of conditional probabilities can be summarized by the Bayes' theorem formula:

<math display="block">
  <mrow>
    <mi>P(A | B)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(A and B)</mi>
      <mi>P(B)</mi>
    </mfrac>
  </mrow>
</math>

If we were to calculate our previous example using this formula, it would look like this (we'll use UMC for `upper middle class` and `WC` for working class):

<math display="block">
  <mrow>
    <mi>P(subjective UMC | objective WC)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(subjective UMC and objective WC)</mi>
      <mi>P(objective WC)</mi>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(subjective UMC | objective WC)</mi>
    <mo>=</mo>
    <mfrac>
      <mfrac>
        <mn>8</mn>
        <mn>98</mn>
      </mfrac>
      <mfrac>
        <mn>48</mn>
        <mn>98</mn>
      </mfrac>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(subjective UMC | objective WC)</mi>
    <mo>=</mo>
    <mfrac>
      <mn>8</mn>
      <mn>48</mn>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(subjective UMC | objective WC)</mi>
    <mo>=</mo>
    <mn>0.1666667</mn>
  </mrow>
</math>

And it produces exactly the same value we saw before. While this ended up being much more work than what we had when doing the simple conditional probability, the simple case was only possible because we had all the counts already neatly organized for us, the main value of Bayes' theorem is when we don't have all the information readily available like that. Let's look at an example for it:

> The 2010 American Community Survey estimates that 14.6% of Americans live below the poverty line, 20.7% speak a language other than English at home, and 4.2% fall into both categories.

Given the information below, what percentage of americans live below the poverty line given that they speak a language other than English at home? Let's get the equation done:

<math display="block">
  <mrow>
    <mi>P(below poverty line | not english at home)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(below poverty line and not english at home)</mi>
      <mi>P(not english at home)</mi>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(below poverty line | not english at home)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>0.042</mi>
      <mi>0.207</mi>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(below poverty line | not english at home)</mi>
    <mo>=</mo>
    <mi>0.2028986</mi>
  </mrow>
</math>

So, around `20%` of americans below the poverty line don't speak English at home.

Earlier we said that if we wanted to calculate `P(A and B)` as `P(A) × P(B)` we had to know `P(A)` and `P(B)` are independent events. If we didn't know if they were independent or not we had no way to calculate this probability. Now that we know Bayes' theorem we can use it to build a general product rule, he's how it would look like:

<math display="block">
  <mrow>
    <mi>P(A | B)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(A and B)</mi>
      <mi>P(B)</mi>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(A | B)</mi>
    <mo>×</mo>
    <mi>P(B)</mi>
    <mo>=</mo>
    <mi>P(A and B)</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(A and B)</mi>
    <mo>=</mo>
    <mi>P(A | B)</mi>
    <mo>×</mo>
    <mi>P(B)</mi>
  </mrow>
</math>

So we just shuffle the terms around and now we can calculate `P(A and B)` even if they're not independent if we have `P(A|B)` and `P(B)`. Also, with Bayes' theorem we can also verify the statement we said before about **independent events**, where we said that events A and B are said to be independent when `P(A|B) = P(A)`.

Starting from the theorem itself:

<math display="block">
  <mrow>
    <mi>P(A | B)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(A and B)</mi>
      <mi>P(B)</mi>
    </mfrac>
  </mrow>
</math>

We know that if they're independent, `P(A and B)` is `P(A) × P(B)`, so let's replace them in the formula:

<math display="block">
  <mrow>
    <mi>P(A | B)</mi>
    <mo>=</mo>
    <mfrac>
      <mrow>
        <mi>P(A)</mi>
        <mo>×</mo>
        <mi>P(B)</mi>
      </mrow>
      <mi>P(B)</mi>
    </mfrac>
  </mrow>
</math>

The two `P(B)` cancel each other so we end up with:

<math display="block">
  <mrow>
    <mi>P(A | B)</mi>
    <mo>=</mo>
    <mi>P(A)</mi>
  </mrow>
</math>

So here we can finally prove what we have said before about independent events using Bayes' theorem.

## Probability trees

Probability trees are useful ways of visualizing data when you don't have the means to build a contingency table out of it. It can greatly help you calculate conditional probabilities using Bayes' theorem as it produces a simple and intuitive way of associating the various conditions on your data. Let's look at an example:

> As of 2009, Swaziland had the highest HIV prevalence in the world. 25.9% of it's population is infected with HIV. The ELISA test is one of the first and most accurate tests for HIV. For those who carry HIV, the ELISA test is 99.7% accurate. For those who do not carry HIV, the test is 92.6% accurate. If an individual from Swaziland has tested positive, what is the probability that he carries HIV?

So let's look at what we've been given already:

<math display="block">
  <mrow>
    <mi>P(HIV)</mi>
    <mo>=</mo>
    <mi>0.259</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(+ | HIV)</mi>
    <mo>=</mo>
    <mi>0.997</mi>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(- | no HIV)</mi>
    <mo>=</mo>
    <mi>0.926</mi>
  </mrow>
</math>

But what we want to find is `P(HIV | +)`, the probability that someone who tested positive and has HIV, the inverse of the conditional we're given, `P(+ | HIV)`. Let's build our probability tree:

      has HIV           - 0.259
        tested +          - 0.997 - P(HIV and +)    = 0.259 × 0.997 = 0.258223
        tested -          - 0.003 - P(HIV and -)    = 0.259 × 0.003 = 0.000777

      does not have HIV - 0.741
        tested +          - 0.074 - P(no HIV and +) = 0.741 × 0.074 = 0.054834
        tested -          - 0.926 - P(no HIV and -) = 0.741 × 0.926 = 0.686166

Let's now get Bayes' theorem in place:

<math display="block">
  <mrow>
    <mi>P(HIV | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(HIV and +)</mi>
      <mi>P(+)</mi>
    </mfrac>
  </mrow>
</math>

We know `P(HIV and +)` so we can replace it:

<math display="block">
  <mrow>
    <mi>P(HIV | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>0.258223</mi>
      <mi>P(+)</mi>
    </mfrac>
  </mrow>
</math>

And `P(+)` is the sum of the two positive cases, `P(no HIV and +) + P(HIV and +)`:

<math display="block">
  <mrow>
    <mi>P(HIV | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>0.258223</mi>
      <mrow>
        <mn>0.054834</mn>
        <mo>+</mo>
        <mn>0.258223</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(HIV | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mn>0.258223</mn>
      <mn>0.313057</mn>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(HIV | +)</mi>
    <mo>=</mo>
    <mn>0.8248434</mn>
  </mrow>
</math>

Building the probability tree showed us all the values we already had so calculating the actual probability was just plugging the values at Bayes' theorem formula, a dead simple way of calculating conditional probabilities.

## Introducing bayesian inference

We can use the bayesian approach to statistics to infer possible outcomes of events as we collect data about them.

Imagine we have a six sided and a twelve sided die, a person holds each of these dice in their hands and we have to figure out which hand holds the twelve sided die given we can ask the person to roll a die and it will tell us if the roll was `≥ 4` or not.

We have two cases here, twelve sided die on the right hand or on the left hand so the probability of one or the other happening is `50%`. We say this is the **prior** probability, as it is the probability we have assumed (or calculated) before collecting more data about the process.

Let's build a probability tree of this assuming we want to know what's in the right hand:

    12 sided die on the right     - 0.5
      roll ≥ 4                      - 0.75 - P(12 and ≥ 4) = 0.5 × 0.75 = 0.375
      roll < 4                      - 0.25 - P(12 and < 4) = 0.5 × 0.25 = 0.125

    6 sided die on the right      - 0.5
      roll ≥ 4                      - 0.5  - P(6 and ≥ 4) = 0.5 × 0.5 = 0.25
      roll < 4                      - 0.5  - P(6 and < 4) = 0.5 × 0.5 = 0.25

Now that we have the tree built, let's pick the right hand and roll a die. Once we do this, we get the answer that the result was `≥ 4`. Can we use this information to improve our probabilities?

Yes, we'll just Bayes' theorem for it:

<math display="block">
  <mrow>
    <mi>P(12 | ≥ 4)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(12 and ≥ 4)</mi>
      <mi>P(≥ 4)</mi>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(12 | ≥ 4)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>0.375</mi>
      <mrow>
        <mn>0.375</mn>
        <mo>+</mo>
        <mn>0.25</mm>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(12 | ≥ 4)</mi>
    <mo>=</mo>
    <mn>0.6</mn>
  </mrow>
</math>

So, given we already know we rolled a `≥ 4` from the right hand, the probability of the right hand having the 12 sided die is now `60%`. While simple, this allows us to factor the data collection we're doing into the statistical process in a way that allows us to predict what could possibily happen and even measure the confidency of the prediction.

This output value is called the **posterior** and if we wanted to get more data we could just use this value as the **prior** for another run asking the person to roll the die again and we would again evaluate the Bayes' theorem and re-calculate our `posterior` value.

When talking about posteriors, we'll usually define them as `P(hypothesis | data)`, as the condition will always be on the data we are collecting to validate the hypothesis.

## Bayesian inference example - mammogram

In this example we're provided with the following probabilities:

* 1.7% of women have breast cancer;
* mammographies identify 78% of women who really have breast cancer;
* 10% of all mammographies are false positives;

The first question we're asked is:

> If the mammogram yields a positive result, what is the probability this person actually has breast cancer?

So, what we want is the probability `P(BC | +)`. Let's start by building our probability tree:

    has breast cancer - 0.017
      positive mammogram - 0.78 - P(BC and +) = 0.017 × 0.78 = 0.01326
      negative mammogram - 0.22 - P(BC and -) = 0.017 × 0.22 = 0.00374

    no breast cancer  - 0.993
      positive mammogram - 0.10 - P(no BC and +) = 0.993 × 0.10 = 0.0993
      negative mammogram - 0.90 - P(no BC and -) = 0.993 × 0.90 = 0.8937

With the probability tree, we can build the bayes' theorem equation:

<math display="block">
  <mrow>
    <mi>P(BC | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(BC and +)</mi>
      <mi>P(+)</mi>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(BC | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mn>0.01326</mn>
      <mrow>
        <mn>0.01326</mn>
        <mo>+</mo>
        <mn>0.0993</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(BC | +)</mi>
    <mo>=</mo>
    <mn>0.1178038</mn>
  </mrow>
</math>

So, given the exam was positive, the probability of having breast cancer is around `12%`. Now, let's get to the next question:

> Now that we know that the patient tested positive the first time, if we test a second time, what's the probability that the person actually has breast cancer if this second mammogram yields positive as well?

This is where we tie in our previous knowledge about bayesian inference. Our original priors were the values provided by the example but now we have this posterior of `12%` that we will use as the prior for the new calculation since the condition is that we already know that the first exam was positive. Let's start by building the probability tree again:

    has breast cancer - 0.1178038
      positive mammogram - 0.78 - P(BC and +) = 0.1178038 × 0.78 = 0.09188696
      negative mammogram - 0.22 - P(BC and -) = 0.1178038 × 0.22 = 0.02591684

    no breast cancer  - 0.8821962
      positive mammogram - 0.10 - P(no BC and +) = 0.8821962 × 0.10 = 0.08821962
      negative mammogram - 0.90 - P(no BC and -) = 0.8821962 × 0.90 = 0.7939766

The only thing we change here is the `has breast cancer` and the `does not have breast cancer` probabilities as the exam results probabilities stay the same. We then recalculate the `and` probabilities and we can now get back to answer the question:

<math display="block">
  <mrow>
    <mi>P(BC | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mi>P(BC and +)</mi>
      <mi>P(+)</mi>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(BC | +)</mi>
    <mo>=</mo>
    <mfrac>
      <mn>0.09188696</mn>
      <mrow>
        <mn>0.09188696</mn>
        <mo>+</mo>
        <mn>0.08821962</mn>
      </mrow>
    </mfrac>
  </mrow>
</math>
<math display="block">
  <mrow>
    <mi>P(BC | +)</mi>
    <mo>=</mo>
    <mn>0.510181</mn>
  </mrow>
</math>

And the result is that this second probability is much higher than the other, at `51%`.







.
