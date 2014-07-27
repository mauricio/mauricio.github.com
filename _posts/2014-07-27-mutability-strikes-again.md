---
layout: post
title: Mutability strikes again
subtitle: at the worst moment possible
keywords: ruby, factory-girl, rspec, mutability
tags:
- ruby
- useful
---

[Full source for this example](https://github.com/mauricio/broken_factory_example).

While refactoring code and running specs to validate the code was still working, I decided it was also a good moment to refactor the tests as well.

These tests were pretty old and didn't follow some of the current practices for our test suite (use factories, rspec's `expect` syntax and the like) and it was a good opportunity to move object creation logic to a single place, since the objects under test are really important for this specific app and these factories would replace a truckload of copied and pasted code.

The code went from being the full creation declared in many different before blocks like:

{% highlight ruby %}
before do
  @user = User.create(
    first_name: "John",
    last_name: "Doe",
    options: { hometown: "Tokyo" }
  )
end
# various matchers
{% endhighlight %}

To be a single factory:

{% highlight ruby %}
FactoryGirl.define do

  factory :user do
    first_name "John"
    last_name  "Doe"
    options hometown: "Tokyo"
  end

end
{% endhighlight %}

That was simply used with a `let` block at the spec:

{% highlight ruby %}
describe User do

  let(:user) { create(:user) }

  it 'should allow setting more options' do
    user.options[:timezone] = "UTC"
    expect(user.options).to eq(hometown: "Tokyo", timezone: "UTC")
  end

  it 'should allow setting yet another option' do
    user.options[:state] = "The Shire"
    expect(user.options).to eq(hometown: "Tokyo", state: "The Shire")
  end

end
{% endhighlight %}

So far, so good, running specs one by one shows everything works after the spec refactoring. When I finally run all specs together, *surprise*, specs start to fail with this weird error:

    1) User should allow setting yet another option
       Failure/Error: expect(user.options).to eq(hometown: "Tokyo", state: "The Shire")

         expected: {:hometown=>"Tokyo", :state=>"The Shire"}
              got: {:hometown=>"Tokyo", :timezone=>"UTC", :state=>"The Shire"}

         (compared using ==)

         Diff:
         @@ -1,3 +1,4 @@
          :hometown => "Tokyo",
          :state => "The Shire",
         +:timezone => "UTC",

How come this spec has the `timezone` field that was set at the other spec? Each spec get's it's own `user` reference created by the factory since we're using the `let` block. There's no way the same `user` would be reused by both specs.

So, what's wrong here?

It had to me something I did. Before the refactoring, all specs were green, only after I refactored the user creation code to to live at the factory this started happening, my changes are causing this weird behavior.

## Mutable objects at immutable factories

Since running specs one by one did work but running them all together didn't (one spec was seeing state from the other) I had a shared state issue somewhere. Where could that be? It could be where it was being used or where it was being set.

Then I stared at the factory code again:

{% highlight ruby %}
FactoryGirl.define do

  factory :user do
    first_name "John"
    last_name  "Doe"
    options hometown: "Tokyo"
  end

end
{% endhighlight %}

And **BAM**. There it was.

{% highlight ruby %}
options hometown: "Tokyo"
{% endhighlight %}

The factory itself is **immutable**, it never changes after it was _built_ when the code runs and this might have given me the impression that the values I declared there were immutable as well but **they're not**.

To make it more visible, the factory could be written like this:

{% highlight ruby %}
OPTIONS = {hometown: "Tokyo"}
FIRST_NAME = "John"
LAST_NAME = "Doe"

FactoryGirl.define do

  factory :user do
    first_name FIRST_NAME
    last_name  LAST_NAME
    options OPTIONS
  end

end  
{% endhighlight %}

Now the issue is pretty visible, the `hash` given to the `options` attribute is created only once (when the factory is built) and it's reused for **all** objects that are created out of that factory. So whenever I did a change at this hash it would be visible by all the other objects that were created from it as well.

And this isn't just for hashes, any mutable object you declare at your factories, like `strings` (remember, strings are mutable in Ruby), `arrays` and the like could suffer from exactly the same effect.

For instance, to make it fail with strings you could use something like this:

{% highlight ruby %}
it 'should change the full name if first name is changed' do
  user.first_name << "ny"
  expect(user.full_name).to eq("Johnny Doe")
end

it 'should change the full name of the last name is changed' do
  user.last_name << "rn"
  expect(user.full_name).to eq("John Doern")
end  
{% endhighlight %}

Since the first spec mutates the actual string object, the second one will see `Johnny Doern` as a result. If you run the second one first, the first one will fail because the name will be `Johny Doern` instead of the expeted `John Doe`.

## Expect the worst by default

Now when declaring factories for your objects and setting mutable values, it's definitely simpler to go for the *always create a new object* solution, your factory doesn't even have to change that much:

{% highlight ruby %}
FactoryGirl.define do

  factory :user do
    first_name { "John" }
    last_name  { "Doe" }
    options do
      { hometown: "Tokyo" }
    end
  end

end
{% endhighlight %}

Using blocks for computing the values will guarantee that each object will get it's own set of mutable objects and they will never be reused across different specs.

And with this the test suite runs and shows all tests to be green.

So, when using factories (and even when writing code in general):

* Avoid using mutable values if possible;
* If they can't be avoided, replace them fully instead of mutating in place (if I had used `user.options = options.merge(timezone: "UTC")`) the code would not break the way it did);
* If you have to mutate them in place, make sure the factories are always creating new values for **every** run;

After wasting some of my day trying to figure this out, I have definitely learned yet another lesson as to why I shouldn't be mutating stuff.
