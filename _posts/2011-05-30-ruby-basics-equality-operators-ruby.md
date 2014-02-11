---
layout: post
title: Ruby Basics - Equality operators in Ruby
tags:
- useful
- ruby
---
After [Greg Sterndale's](http://gregsterndale.com/) presentation on a [boston-rb](http://bostonrb.org/) hackfest earlier this month I noticed that not everyone knew the operators available for equality and comparisons in Ruby. Why not take the dust away from the blog and write about it, then?

Ruby has many equality operators, some of them we use and see everywhere in our applications (like the usual double equal - “==”) and some are also used everywhere but we don’t really get to see them (like the triple equal or case equal operator – “===”). So let’s dig into how Ruby implements comparisons between our objects.

You can see the full source code for this tutorial on [Github](https://github.com/mauricio/ruby-equality-operators).

## What does it mean to be equal?

Maybe this is something from my Java past, but I find it to be really useful to first define what being “equal” really means. Objects have identities for the Ruby interpreter, you can easy check this by calling the object_id method:

{% highlight ruby %}
some_string = 'some string'
=> "some string"
another_string = 'another_string'
=> "another_string"
[ some_string.object_id, another_string.object_id ]
=> [2164900860, 2164888440]
{% endhighlight %}

As you keep on creating new objects, Ruby itself will give you an object_id for each of them and you could possibly use this to identify all your objects. But there’s a little gotcha:

{% highlight ruby %}
matz = 'matz'
=> "matz"
matz_2 = 'matz'
=> "matz"
[ matz.object_id, matz_2.object_id ]
=> [2164840660, 2164818480]
{% endhighlight %}

The two objects represent exactly the same value, but each of them has it’s own object_id, as the Ruby interpreter has no idea these two objects are the same. So, while object_id could be a shortcut to define the identity of our objects, each object has it’s own way to define what being equal to someone else really means.

Two Strings are equal when they represent exactly the same sequence of characters, two people would be the same if they had the same social security number (or the same CPF if you were in Brazil). To be able to implement this kind of identity the language must offer you with hooks for this and in Ruby these hooks are the equality methods.

## "==" - double equals

The double equals method should implement the general identity algorithm to an object, which usually means that you should compare the object attributes and not if they are the same object in memory. And given Ruby is dynamically typed language, you should try not to depend on types, but on methods, instead of checking if the object is from an specific class, check if it responds to an specific method:
{% highlight ruby %}
class Meter

  def initialize( value )
    @value = value
  end

  def to_meters
    @value.to_f
  end

  def ==( other )
    if other.respond_to?( :to_meters )
      self.to_meters == other.to_meters
    end
  end

end
{% endhighlight %}

Instead of checking on the parameter type I check if the object has the method I expect to use, I it has then I do the comparison, if it doesn’t a “false” is sent up, which means that the objects are not equivalent.

## The “hash” method

If you're already implementing "==", you should also implement "eql?" and "hash" methods, even if you have never seen these methods being called anywhere. The reason is these are the methods the Hash object is going to use to compare your object if you're using in as a Hash key. The thing is, Hashes have to be fast to figure out if a key is already in there and to be able to do this they just avoid comparing every single object, they just go by "clustering" objects in groups by using the value returned by your object's "hash" method and then, once in a cluster, they compare the objects themselves using "eql?".

Then searching for a key in a Hash, they first call “hash” in the key to figure out in which group it would be, then they compare the key with all the other keys in the group using the “eql?” method. In a worst-case scenario, we would compare with 3 objects (and the hash has nine of them), which is quite nice. If you were using an array, your worst case would be 9 comparisons.

For a quick example of how this could affect your code, let’s check this class:

{% highlight ruby %}
class StringWithoutHash

  def initialize(text)
    @text = text
  end

  def to_text
    @text
  end  
  
  def ==(other_value)
    if other_value.respond_to?(:to_text)
      self.to_text == other_value.to_text
    end
  end

end
{% endhighlight %}

The "==" method has been implemented correctly, but we haven't implemented "hash" and "eql?", so the two objects will end up in different clusters they we won't be able to figure out they're the same object inside the hash.

{% highlight ruby %}
context 'without hash and eql? methods' do

  it 'should be equal' do
    @first  = StringWithoutHash.new('first')
    @second = StringWithoutHash.new('first')
    @first.should == @second
  end

  it 'should add as two different keys in the hash' do

    @texts = {}

    10.times do
      @texts[ StringWithoutHash.new('first') ] = 'one'
    end

    @texts.keys.size.should == 10

  end

end
{% endhighlight %}  

Even with `@first` and `@second` representing exactly the same text (and being equal) they still generate two keys in the Hash instead of one because we did not implement the “hash”  and "eql?" methods. The general rule is that if you override “==” you should also override “hash” and "eql?". When implementing “hash”, a basic rule to follow is if two objects are “==” they must generate exactly the same hash value (so they can be found in a Hash object), but two objects can have the same hash value but still be different (they belong to the same group but are not the same object).

Here's a subclass of our StringWithoutHash, StringWithHash, that correctly implements both methods (and the "eql?" method itself is just using the "==", we don't even have to bother writting code for it):

{% highlight ruby %}
class StringWithHash < StringWithoutHash

  def eql?( other )
    self == other
  end  
  
  def hash
    @text.hash
  end

end
{% endhighlight %}

And here are some specs showing how it works correctly now:

{% highlight ruby %}
context 'with hash and eql? methods' do

  it 'should be equal' do
    @first  = StringWithHash.new('first')
    @second = StringWithHash.new('first')
    @first.should == @second
  end

  it 'should add as a single key in the hash' do

    @texts = {}

    50.times do
      @texts[ StringWithHash.new('first') ] = 'one'
    end

    @texts.keys.size.should == 1

  end

end
{% endhighlight %}

So, now that we implemented "eql?" and "hash" correctly even trying to add the object 50 times we stil have a single one, because our code can now be sure that the object is there (or not) as the methods are available.

Unless you know exactly what you’re doing (and you know how Ruby implement it’s hashes) you should not implement your own hashing function, just use a hashing function from a basic object like numbers and strings and you’re done. Here’s the example:

{% highlight ruby %}
class Meter

  # all the other methods

  def hash
    self.to_meters.hash
  end

  def eql?( other )
    self == other
  end 

end
{% endhighlight %}

Here, instead of adding my own “hash” function I just reuse the hash method on Float, which already does it the right way. And unless you have some specific needs you should be doing the same.

## "===" - triple equals
Triple equals is an interesting operator, it’s everywhere in Ruby code but most people have never seen it in real code out there. But, how come it’s everywhere and no one has ever seen it? It’s hidden inside a common control structure, the “case/when”. Whenever you’re using a “case/when” you’re using, in fact, the “===” operator and this is what makes the case statement on Ruby much more powerful than it’s counterpart in languages like C or Java.

Let’s look at a statement:

{% highlight ruby %}
age = 19

case age
  when 1..18
    puts 'just out of college'
  when 19..30
    puts 'wild years'
  when 31..40
    puts 'i better find a job in a big corp'
  else
    puts 'retirement plan'
end
{% endhighlight %}

This one will print ‘wild years’ and it’s using the ‘===’ operator. Can you see how it’s working? Here’s this same case/when done with if’s:

{% highlight ruby %}
if 1..18 === age
  puts 'just out of college'
elsif 19..30 === age
  puts 'wild years'
elsif 31..40 === age
  puts 'i better find a job in a big corp'
else
  puts 'retirement plan'
end
{% endhighlight %}

In the end, the case/when statement is just a glorified if using the ‘===’ operator to simplify your job (and also make you type less). In the language itself, the triple equals is used mostly to as a “grouping” operator, by getting a value and figuring out at which group it belongs to.

In our example it’s a group of ages represented by Range objects, but you’ll see this being used to figure out if an object is from an specific class, if a string matches a regular expression and the like. And all of this is possible because the method (‘===’) is not called at the object in the “case” definition but on each “when”.

Imagine you have Rectangles and you want to figure out if a specific Point is inside the Rectangle, this is a perfect fit for the triple equals. Let’s look at a sample implementation:

{% highlight ruby %}
class Point

  include Comparable

  attr_accessor :x, :y

  def initialize(x, y)
    self.x = x
    self.y = y
  end

  def hash
    "#{x}-#{y}".hash
  end

  def <=>(other)

    result = nil

    if other.respond_to?(:x) && other.respond_to?(:y)

      result = if self.x == other.x && self.y == other.y
                 0
               elsif self.x > other.x && self.y > other.y
                 1
               else
                 -1
               end

    end

    result

  end

end
{% endhighlight %}

And the Rectangle class:

{% highlight ruby %}
class Rectangle

  attr_accessor :start, :end

  def initialize( x1, y1, x2, y2 )
    self.start = Point.new( x1, y1 )
    self.end = Point.new( x2, y2 )

    if self.start >= self.end
      raise "Start #{self.start.inspect} should be less than end #{self.end.inspect}"
    end
  end

  def === (other)
    if other.respond_to?(:x) && other.respond_to?( :y )
       other.between?( self.start, self.end )
    else
      self == other
    end
  end

  def == (other)
    if other.respond_to?( :start ) && other.respond_to?( :end )
      self.start == other.start && self.end == other.end
    end
  end

end
{% endhighlight %}

And now some usage:

{% highlight ruby %}
point = Point.new( 2, 4 )

case point
  when Rectangle.new( 0, 3, 5, 8  )
    puts 'found it here'
  when Rectangle.new( 3, 3, 10, 15  )
    puts 'i will not match'
end
{% endhighlight %}

The ‘===’ method will be called on Rectangle giving it a Point object and it’s going to figure out if that point is inside the Rectangle or not.

## Making your objects Comparable

If you looked closely at the Point object you will notice that it includes the Comparable module and implements a method defined as `<=>`, the flying saucer operator. The flying saucer operator is to be used as means to sort your objects in a collection, but the Comparable module brings some interesting functionality for classes that implement it.

The idea behind the `<=>` operator is that when you call it on a object, this object must define it’s position compared to the other object given as a parameter. If the receiver of the call is greater than the argument, it should return 1, if they re the same, it should return 0, if the receiver is less than the argument it should return -1 and if they’re not compatible it should return nil.

Once you implement the flying saucer, you can just include Comparable in your class and the following methods are now implemented for you:

* `>`
* `>=`
* `<`
* `<=`
* `==`
* `between?`

This is why we could use the `between?` method in Point when implementing the “===” operator on Rectangle. By implementing `<=>` and including Comparable we get a lot of functionality for our objects for free and we also have a great example of how you should plan to build your own modules on your projects.

Going back to our first example, the Meter class, we could add new classes for Inch and Foot and have them all share the same equality implementation. First, we define that all our classes will have a to_meters method that will return their value in meters. Then we create our module:

{% highlight ruby %}
module MeterComparator

  include Comparable

  def <=> (other)
    result = nil

    if other.respond_to?(:to_meters)
      receiver_value = self.to_meters
      argument_value = other.to_meters

      result = if receiver_value == argument_value
                 0
               elsif receiver_value < argument_value
                 -1
               else
                 1
               end
    end

    result
  end

  def inspect
    "#<#{self.class}:#{self.hash} size_in_meters=#{self.to_meters}>"
  end

  def hash
    self.to_meters.hash
  end

end
{% endhighlight %}

We implemented the `<=>` operator and (also the “hash” method, don’t forget it!) for this module and included Comparable, which will make all classes including it to be comparable too. Let’s look at how our new Meter, Inch and Foot will look like now:

{% highlight ruby %}
class Meter

  include MeterComparator

  def initialize( value )
    @value = value
  end

  def to_meters
    @value.to_f
  end

end
{% endhighlight %}

And Inch:

{% highlight ruby %}
class Inch

  include MeterComparator

  def initialize( value )
    @value = value
  end

  def to_meters
    @value.to_f / 39.370
  end

end
{% endhighlight %}

And finally Foot:

{% highlight ruby %}
class Foot

  include MeterComparator

  def initialize( value )
    @value = value
  end

  def to_meters
    @value.to_f / 3.2808
  end

end
{% endhighlight %}

All classes share the same comparison methods so we can use them all interchangeably in our code, we can even safely compare them with each other and they’ll yield the correct results:

{% highlight ruby %}
context 'comparing meters with inches' do

  it 'should be true when they both represent the same distance' do
    @meter = Meter.new(4)
    @inch  = Inch.new(157.48)

    @meter.should == @inch
  end

end

context 'comparing meters to feet' do

  it 'should be true when they both represent the same distance' do
    @meter = Meter.new(8)
    @foot  = Foot.new(26.2464)

    @meter.should == @foot
  end

end

context 'comparing feet to inches' do

  it 'should be true when they both represent the same distance' do
    @foot = Foot.new(26.2464)
    @inch = Inch.new(314.96)

    @foot.should == @inch
  end

end

context 'when sorting objects' do

  before do
    @meter    = Meter.new(1.5)
    @inch     = Inch.new(157.48)
    @foot     = Foot.new(26.2464)
    @measures = [@inch, @meter, @foot].sort
  end

  it 'should order them by size correctly' do
    @measures.first == @meter
    @measures[1] == @inch
    @measures.last == @foot
  end

end
{% endhighlight %}

You can mix and mingle different measures and they’ll all play and compare nicely to each other, they just have to implement the “to_meters” method and include the MeterComparator class, simple and right to the point implementation.

Also, once you include the Comparable module your objects become "sortable" in an array, you can use the "sort" and "sort!" methods in Array. The order is ascending as defined by your "<=>" method implementation.

## “eql?” and “equal?”

Technically, “eql?” is should behave just like “==” and it's also the method selected by the **Hash** class to figure out of your object is already in a "hash cluster" (as we have discussed above). You compare two objects to see if they represent the same values. Usually you can just override "eql?" and delegate it's call to "==", as we did in our examples. **This is not already done for you**, the default "eql?" implementation at the **Object** class uses comparison between "object_id" values and this is usually **NOT** what you want, so, make sure that if you implement "==" you also override "eql?" and implement "hash".

There’s one exception, though, Numeric objects will convert different types when compared using “==” but will not do this when using “eql?”, so:

{% highlight ruby %}
5 == 5.0 # is true
{% endhighlight %}

But:

{% highlight ruby %}
5.eql?( 5.0 ) # is false
{% endhighlight %}

And “equal?” is a little bit exoteric as it will compare if two objects are the same object in memory. You should never ever override this method. In fact, you’re better of ignoring the fact that “equal?” exist at all for your own safety. And don’t say you have not been warned.

## Closing thoughts

While there’s a lot to be said about comparing objects in Ruby, the final implementation is quite simple and modules like Comparable make it even simpler as long as you know they exist. Now there’s no reason to correctly implement comparison for your Ruby objects and never forget the “hash” method again! ;)