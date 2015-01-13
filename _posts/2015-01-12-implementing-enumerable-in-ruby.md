---
layout: post
title: Implementing Enumerable in Ruby
subtitle: an abstraction exercise
keywords: ruby, collection, enumerable, data structures, array
tags:
- useful
- ruby
---

Ruby's [Enumerable](http://ruby-doc.org/core/Enumerable.html) is, by far, one of the greatest examples of how modules should be made. It offers a large collection of methods that are useful for those handling data structures and only requires you to implement a single method, `each`. So, any class that could behave like a collection and implement an `each` method can be used as an `Enumerable`.

A nice exercise to understand how `Enumerable` works is implementing it's main methods. By implementing each method ourselves, we understand better what each one of them is doing and how it was possible to build this much functionality requiring only a single method to be implemented.

First, we need a class what will include our `CustomEnumerable`, let's define it:

{% highlight ruby %}
class ArrayWrapper

  include CustomEnumerable

  def initialize(*items)
    @items = items.flatten
  end

  def each(&block)
    @items.each(&block)
    self
  end

  def ==(other)
    @items == other
  end

end  
{% endhighlight %}

Not much here, it includes `CustomEnumerable` (our own `Enumerable` implementation) and is basically a wrapper around an `Array`. The `==` method is also implemented here just so we can easily use the `eq` `RSpec` matcher when implementing our solution, it is not a requirement for a functional `Enumerable` implementation.

# `map`

The documentation for `map` says:

> Returns a new array with the results of running block once for every element in enum.

So, our code has to call the block given on every item of the collection and then build an array of the results of every call. Let's implement it:

{% highlight ruby %}
module CustomEnumerable

  def map(&block)
    result = []
    each do |element|
      result << block.call(element)
    end
    result
  end

end
{% endhighlight %}

This will be a pattern for almost all the methods we will be creating, create the destination array, call each on itself and then do the actual work. It's important to notice that our implementation knows nothing about where it is being included, the only expectation it has is that there is an `each` method implemented that yields to a block with an object.

To see `map` in action, let's see how we could create a new array by multiplying every number on it by `2`:

{% highlight ruby %}
it 'maps the numbers multiplying them by 2' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.map do |n|
    n * 2
  end

  expect(result).to eq([2, 4, 6, 8])
end  
{% endhighlight %}

# `find`

Here is what the docs say about `find`:

> Passes each entry in enum to block. Returns the first for which block is not false. If no object matches, calls ifnone and returns its result when it is specified, or returns nil otherwise.

`find` is used to find an item inside an `Enumerable` given it matches the block given to the method. If the item is not found, it returns the default value. Let's build it:

{% highlight ruby %}
def find(ifnone = nil, &block)
  result = nil
  found = false
  each do |element|
    if block.call(element)
      result = element
      found = true
      break
    end
  end
  found ? result : ifnone && ifnone.call
end
{% endhighlight %}

First we setup the variables that will contain the result if we find it and a signal variable if we have really found the value. Why don't we just use `result` with `nil` to signal that we have not found anything? Because `nil` might actually be what the user is looking for!

So we really need to know if we have found something (whatever it is) or not before returning. And if we don't find anything, we call `ifnone` and use it's result as the result of the operation, if `ifnone` is `nil` we just return it.

There are many cases for `find`. For instance, we need to be able to `find` an item:

{% highlight ruby %}
it 'finds the item given a predicate' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.find do |element|
    element == 3
  end

  expect(result).to eq(3)
end
{% endhighlight %}

We could want to change the default value if it does not match anything:

{% highlight ruby %}
it 'returns the ifnone value if no item is found' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.find(lambda {0}) do |element|
    element < 1
  end
  expect(result).to eq(0)
end
{% endhighlight %}

This is useful if you always want to return a value back, even when nothing was found by our search.

And by default if nothing is found, we need to return `nil`:

{% highlight ruby %}
it "returns nil if it can't find anything" do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.find do |element|
    element == 10
  end
  expect(result).to be_nil
end
{% endhighlight %}

While useful, `find` returns once it matches the first value inside the collection, what if I wanted to return *all* values inside the `Enumerable` that match a criteria?

We use `find_all`!

# `find_all`

The docs say:

> Returns an array containing all elements of enum for which the given block returns a true value.

So, now we don't have defaults anymore, the method always returns an array of all the items that matched the block (or an empty array in case no match happens), let's build it:

{% highlight ruby %}
def find_all(&block)
  result = []
  each do |element|
    if block.call(element)
      result << element
    end
  end
  result
end
{% endhighlight %}

Since `find` exists at the very first match, we can't really reuse it here, the method has to be built on top of `each` from scratch. We build an array, then traverse our enumerable checking every item, once an item matches the block, we add it to the result. Once we're done, we return the collection of items that match.

Let's loot at a few examples:

{% highlight ruby %}
it 'finds all the numbers that are greater than 2' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.find_all do |element|
    element > 2
  end
  expect(result).to eq([3,4])
end

it 'does not find anything' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.find_all do |element|
    element > 4
  end
  expect(result).to be_empty
end
{% endhighlight %}

Even in the case of no matches, an array (albeit empty) is returned so the code that uses `find_all` needs to remember that it has to consider this option and verify if the array has items or not (instead of checking for `nil` as it would be done with `find`).

# `reduce`

`reduce` or `inject` (also known as `foldLeft` in other languages like OCaml and Scala) is a method that applies a function to an accumulator and an item inside the `Enumerable` and produces the accumulator object at the end of the run. While it sounds weird, it's actually a very useful function whenever you need to perform a function that *aggregates* data inside a collection.

Let's look at what the docs say about it:

> Combines all elements of enum by applying a binary operation, specified by a block or a symbol that names a method or operator.

> If you specify a block, then for each element in enum the block is passed an accumulator value (memo) and the element. If you specify a symbol instead, then each element in the collection will be passed to the named method of memo. In either case, the result becomes the new value for memo. At the end of the iteration, the final value of memo is the return value for the method.

> If you do not explicitly specify an initial value for memo, then the first element of collection is used as the initial value of memo.

So we have to either take a block or a symbol and we might or might not get an initial value, if we don't, assume the first item is the initial value. This implementation will actually be a bit tricky, let's start with the simple case, we give it a block and an initial value:

{% highlight ruby %}
def reduce(accumulator, &block)
  each do |element|
    accumulator = block.call(accumulator, element)
  end
  accumulator
end
{% endhighlight %}

So, this is pretty simple, we just call block with `accumulator` and `element` and the next `accumulator` is whatever the block call produces. Pretty simple implementation, but this abstraction is incredibly powerful and available on all functional programming languages for aggregations (the `reduce` here is the `reduce` from the `map-reduce` paradigm!).

Let's see it in use:

{% highlight ruby %}
it 'sums all numbers' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.reduce(0) do |accumulator,element|
    accumulator + element
  end
  expect(result).to eq(10)
end
{% endhighlight %}

And here we have a simple reduce function that takes the accumulator and then produces the sum of all items. It's also important to verify the case of the empty `Enumerable`, if it happens to be empty, it should just return the initial value provided:

{% highlight ruby %}
it 'returns the accumulator if no value was provided' do
  items = ArrayWrapper.new
  result = items.reduce(50) do |accumulator,element|
   accumulator + element
  end
  expect(result).to eq(50)
end
{% endhighlight %}

Now, let's include the first optional parameter, the operation symbol that serves as the operation to be applied instead of a block.

{% highlight ruby %}
def reduce(accumulator, operation = nil, &block)
  if operation && block
    raise ArgumentError, "you must provide either an operation symbol or a block, not both"
  end

  block = case operation
    when Symbol
      lambda { |acc,value| acc.send(operation, value) }
    when nil
      block
    else
      raise ArgumentError, "the operation provided must be a symbol"
  end

  each do |element|
    accumulator = block.call(accumulator, element)
  end
  accumulator
end
{% endhighlight %}

The actual implementation here does not change much, we have included a couple validations to make sure the values are the expected ones and when provided a symbol, we build a block to be used ourselves that just uses `send` to call the method defined by the symbol given as a parameter. The actual loop doesn't change.

Now let's look at some usage:

{% highlight ruby %}
it 'executes the operation provided' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.reduce(0, :+)
  expect(result).to eq(10)
end
{% endhighlight %}

First, the basic usage, calling `reduce` with a symbol that will be applied to the accumulator and every value. This is the same as our first `reduce` example, but now it uses very little code.

Now let's look at the failure cases, first one providing both an operation and a block:

{% highlight ruby %}
it "fails if both a symbol and a block are provided" do
  items = ArrayWrapper.new(1, 2, 3, 4)
  expect do
    items.reduce(0, :+) do |accumulator,element|
      accumulator + element
    end
  end.to raise_error(ArgumentError, "you must provide either an operation symbol or a block, not both")
end
{% endhighlight %}

When both are provided, we must fail as it's impossible to know what the user wanted. Same as if the `operation` provided is not a symbol:

{% highlight ruby %}
it 'fails if the operation provided is not a symbol' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  expect do
    items.reduce(0, '+')
  end.to raise_error(ArgumentError, "the operation provided must be a symbol")
end
{% endhighlight %}

Not a `Symbol`? Sorry, can't use it.

Now for the last step on our implementation, the `accumulator` parameter is now optional. If it isn't available, the first element inside the collection should be used. Now we have 4 cases for the `reduce` call:

* `accumulator` + block
* `accumulator` + `operation`
* `operation`
* no params + block

This time, let's start defining the two specs that are missing, first, the `operation` only call:

{% highlight ruby %}
it 'executes the operation provided without an initial value' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.reduce(:+)
  expect(result).to eq(10)
end
{% endhighlight %}

And, finally, the call with a block alone:

{% highlight ruby %}
it 'executes the block provided without an initial value' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  result = items.reduce do |accumulator,element|
    accumulator + element
  end
  expect(result).to eq(10)
end  
{% endhighlight %}

Why get these two tests here first?

Look at them, they are actually *the same* case, which is the case without an accumulator, the only difference is that one provides a block and the other doesn't, but both will have to pull the first item inside the collection and then run the `reduce` operation.

If we try to run these specs:

    Failures:

    1) CustomEnumerable reduce executes the operation provided without an initial value
      Failure/Error: @items.each(&block)
      NoMethodError:
      undefined method `call' for nil:NilClass
      # ./lib/custom_enumerable.rb:47:in `block in reduce'
      # ./spec/custom_enumerable_spec.rb:12:in `each'
      # ./spec/custom_enumerable_spec.rb:12:in `each'
      # ./lib/custom_enumerable.rb:46:in `reduce'
      # ./spec/custom_enumerable_spec.rb:128:in `block (3 levels) in <top (required)>'

    2) CustomEnumerable reduce executes the block provided without an initial value
      Failure/Error: result = items.reduce do |accumulator,element|
      ArgumentError:
      wrong number of arguments (0 for 1..2)
      # ./lib/custom_enumerable.rb:32:in `reduce'
      # ./spec/custom_enumerable_spec.rb:134:in `block (3 levels) in <top (required)>'

How do we build this? Most of the code will be handling the parameter juggling. Since `reduce` was declared long before `ruby` had named parameters, there is no magic way to decide if the accumulator is an operation or not, we will have to manually check this.

Also, we need a way to get the first item at the collection, otherwise we will end up having to do this inside `reduce` itself. Let's start by implementing `first` then:

{% highlight ruby %}
def first
  found = nil
  each do |element|
    found = element
    break
  end
  found
end
{% endhighlight %}

Using it is quite simple:

{% highlight ruby %}
it 'returns the first element inside a collection' do
  items = ArrayWrapper.new(1, 2, 3, 4)
  expect(items.first).to eq(1)
end

it 'returns nil if the collection is empty' do
  items = ArrayWrapper.new
  expect(items.first).to be_nil
end  
{% endhighlight %}

If you're asking yourself why I'm using `break` and not just returning from the `each` block, try changing the code to:

{% highlight ruby %}
def first
  each do |element|
    return element
  end
end
{% endhighlight %}

What happens now?

The second spec, that expects `nil` to be returned when the collection is empty, fails. Why? Because `each` returns the collection itself once it runs, since the code was never executed (the collection is empty!) `each` just returns itself and not `nil` as our spec expects. So, that's why we need to explicitly declare our return value instead of relying on the iteration.

Now that `first` is also implemented, let's produce the final `reduce` implementation:

{% highlight ruby %}
def reduce(accumulator = nil, operation = nil, &block)
  if accumulator.nil? && operation.nil? && block.nil?
    raise ArgumentError, "you must provide an operation or a block"
  end

  if operation && block
    raise ArgumentError, "you must provide either an operation symbol or a block, not both"
  end

  if operation.nil? && block.nil?
    operation = accumulator
    accumulator = nil
  end

  block = case operation
    when Symbol
      lambda { |acc, value| acc.send(operation, value) }
    when nil
      block
    else
    raise ArgumentError, "the operation provided must be a symbol"
  end

  if accumulator.nil?
    ignore_first = true
    accumulator = first
  end

  index = 0

  each do |element|
    unless ignore_first && index == 0
      accumulator = block.call(accumulator, element)
    end
    index += 1
  end
  accumulator
end  
{% endhighlight %}

Given we don't know exactly how the parameters will be provided or the collection structure, we can't really optimize this call (not unless we duplicate the code a bit, for instance, streamlining the implementation if there is an accumulator). But since we want this code to work for all cases, we will hope classes that include this module will provide implementations more aligned with their structure.

The code starts by verifying all parameters, if no parameters were provided, give it up, there's nothing to do here. Then it starts checking which case we're taking about here, the first check if `operation` and `block` are `nil`, if both are, it means the `accumulator` field *will have to be the operation* and that we don't have an accumulator.

Then we have the `operation` validation we had before and we reach another new piece, the check for the accumulator. If the accumulator is `nil`, we must pull the first item of the collection and we must also instruct the method to ignore the first iteration (as we have manually navigated to it).

Our new `each` loop now checks these special variables for the empty accumulator case so we can safely process the collection without duplicating the values. This would be a nice place for an optimization were we have the same loop we had before if there is an `accumulator`, you can definitely improve this method by including this change yourself.

And this concludes the `reduce` implementation, see if you can come up with better or faster solutions for this, there are definitely better options.

# `reduce` magic

Now that we have `reduce` implemented, there are many methods that can be built around it, like `min` and `max`:

{% highlight ruby %}
def min
  reduce do |accumulator,element|
    accumulator > element ? element : accumulator
  end
end

def max
  reduce do |accumulator,element|
    accumulator < element ? element : accumulator
  end
end
{% endhighlight %}

Since `reduce` already handles the empty case:

{% highlight ruby %}
it 'produces nil if it is empty' do
  items = ArrayWrapper.new
  expect(items.max).to be_nil
end
{% endhighlight %}

And the single element case:

{% highlight ruby %}
it 'produces 1 as the max result' do
  items = ArrayWrapper.new(1)
  expect(items.max).to eq(1)
end
{% endhighlight %}

Our `min` and `max` implementations don't even have to care about it, all they have to do is to provide a block that does the comparison and returns the highest or smallest value found, all the looping and special case handling is done by the `reduce` function we wrote before. Quite powerful, isn't it?

There are many other `Enumerable` methods you can implement just using `reduce`, like `each_with_index`, `each_with_object`, `count`, `max_by`, `min_by` and others, give it a try and complete the enumerable implementation using `reduce` whenever you can.

And here we end our `Enumerable` overview by implementing it in Ruby. The full source code for this example [is available on github](https://github.com/mauricio/enumerable_example).
