---
layout: post
title: Ruby Basics - Equality operators in Ruby
tags:
- basics
- comparable
- comparator
- comparison
- en_US
- equal
- equality
- learning
- rails
- ruby
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  _su_rich_snippet_type: none
  _su_description: Learn how to correctly implement object comparison in Ruby.
  _su_keywords: ruby, comparable, comparison, equal, equality, basics, double equals,
    triple equals, case equality
  dsq_thread_id: '317335749'
  related_posts: '162:53:39:12'
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:1;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:2;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:3;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:4;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:5;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:6;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:7;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
---
<div id="attachment_160" class="wp-caption alignleft" style="width: 132px"><a href="http://www.amazon.com/gp/product/0596516177?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=0596516177"><img class="size-full wp-image-160" title="Dig deeper into Ruby with this book" src="http://techbot.me/wp-content/uploads/2011/01/ruby1.jpg" alt="Dig deeper into Ruby with this book" width="122" height="160" /></a><p class="wp-caption-text">Dig deeper into Ruby with this book</p></div>After <a href="http://gregsterndale.com/">Greg Sterndale's</a> presentation on a <a href="http://bostonrb.org/">boston-rb</a> hackfest earlier this month I noticed that not everyone knew the operators available for equality and comparisons in Ruby. Why not take the dust away from the blog and write about it, then?

Ruby has many equality operators, some of them we use and see everywhere in our applications (like the usual double equal - “==”) and some are also used everywhere but we don’t really get to see them (like the triple equal or case equal operator – “===”). So let’s dig into how Ruby implements comparisons between our objects.

You can see the full source code for this tutorial on <a href="https://github.com/mauricio/ruby-equality-operators">Github</a>.

<!--more-->

<h2>What does it mean to be equal?</h2>
Maybe this is something from my Java past, but I find it to be really useful to first define what being “equal” really means. Objects have identities for the Ruby interpreter, you can easy check this by calling the object_id method:
<pre class="brush:ruby">some_string = 'some string'
=&gt; "some string"
another_string = 'another_string'
=&gt; "another_string"
[ some_string.object_id, another_string.object_id ]
=&gt; [2164900860, 2164888440]</pre>
As you keep on creating new objects, Ruby itself will give you an object_id for each of them and you could possibly use this to identify all your objects. But there’s a little gotcha:
<pre class="brush:ruby">matz = 'matz'
=&gt; "matz"
matz_2 = 'matz'
=&gt; "matz"
[ matz.object_id, matz_2.object_id ]
=&gt; [2164840660, 2164818480]</pre>
The two objects represent exactly the same value, but each of them has it’s own object_id, as the Ruby interpreter has no idea these two objects are the same. So, while object_id could be a shortcut to define the identity of our objects, each object has it’s own way to define what being equal to someone else really means.

Two Strings are equal when they represent exactly the same sequence of characters, two people would be the same if they had the same social security number (or the same CPF if you were in Brazil). To be able to implement this kind of identity the language must offer you with hooks for this and in Ruby these hooks are the equality methods.
<h2>"==" - double equals</h2>
The double equals method should implement the general identity algorithm to an object, which usually means that you should compare the object attributes and not if they are the same object in memory. And given Ruby is dynamically typed language, you should try not to depend on types, but on methods, instead of checking if the object is from an specific class, check if it responds to an specific method:
<pre class="brush:ruby">class Meter

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

end</pre>
Instead of checking on the parameter type I check if the object has the method I expect to use, I it has then I do the comparison, if it doesn’t a “false” is sent up, which means that the objects are not equivalent.

<h2>The “hash” method</h2>

If you're already implementing "==", you should also implement "eql?" and "hash" methods, even if you have never seen these methods being called anywhere. The reason is these are the methods the Hash object is going to use to compare your object if you're using in as a Hash key. The thing is, Hashes have to be fast to figure out if a key is already in there and to be able to do this they just avoid comparing every single object, they just go by "clustering" objects in groups by using the value returned by your object's "hash" method and then, once in a cluster, they compare the objects themselves using "eql?".

Here’s a very naïve diagram of how it would look:

<p><img src="http://techbot.me/wp-content/uploads/2011/05/Hash.png" alt="Naive implementation for a Hash" title="Naive implementation for a Hash" width="792" height="320" class="size-full" /></a></p>

Then searching for a key in a Hash, they first call “hash” in the key to figure out in which group it would be, then they compare the key with all the other keys in the group using the “eql?” method. In a worst-case scenario, we would compare with 3 objects (and the hash has nine of them), which is quite nice. If you were using an array, your worst case would be 9 comparisons.

For a quick example of how this could affect your code, let’s check this class:
<pre class="brush:ruby">class StringWithoutHash

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

end</pre>

The "==" method has been implemented correctly, but we haven't implemented "hash" and "eql?", so the two objects will end up in different clusters they we won't be able to figure out they're the same object inside the hash.

<pre class="brush:ruby">  context 'without hash and eql? methods' do

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

  end</pre>

Even with @first and @second representing exactly the same text (and being equal) they still generate two keys in the Hash instead of one because we did not implement the “hash”  and "eql?" methods. The general rule is that if you override “==” you should also override “hash” and "eql?". When implementing “hash”, a basic rule to follow is if two objects are “==” they must generate exactly the same hash value (so they can be found in a Hash object), but two objects can have the same hash value but still be different (they belong to the same group but are not the same object).

Here's a subclass of our StringWithoutHash, StringWithHash, that correctly implements both methods (and the "eql?" method itself is just using the "==", we don't even have to bother writting code for it):

<pre class="brush:ruby">class StringWithHash < StringWithoutHash

  def eql?( other )
    self == other
  end  
  
  def hash
    @text.hash
  end

end
</pre>

And here are some specs showing how it works correctly now:

<pre class="brush:ruby">context 'with hash and eql? methods' do

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
</pre>

So, now that we implemented "eql?" and "hash" correctly even trying to add the object 50 times we stil have a single one, because our code can now be sure that the object is there (or not) as the methods are available.

Unless you know exactly what you’re doing (and you know how Ruby implement it’s hashes) you should not implement your own hashing function, just use a hashing function from a basic object like numbers and strings and you’re done. Here’s the example:

<pre class="brush:ruby">class Meter

  # all the other methods

  def hash
    self.to_meters.hash
  end

  def eql?( other )
    self == other
  end 

end</pre>

Here, instead of adding my own “hash” function I just reuse the hash method on Float, which already does it the right way. And unless you have some specific needs you should be doing the same.

<h2>"===" - triple equals</h2>
Triple equals is an interesting operator, it’s everywhere in Ruby code but most people have never seen it in real code out there. But, how come it’s everywhere and no one has ever seen it? It’s hidden inside a common control structure, the “case/when”. Whenever you’re using a “case/when” you’re using, in fact, the “===” operator and this is what makes the case statement on Ruby much more powerful than it’s counterpart in languages like C or Java.

Let’s look at a statement:
<pre class="brush:ruby">age = 19

case age
  when 1..18
    puts 'just out of college'
  when 19..30
    puts 'wild years'
  when 31..40
    puts 'i better find a job in a big corp'
  else
    puts 'retirement plan'
end</pre>
This one will print ‘wild years’ and it’s using the ‘===’ operator. Can you see how it’s working? Here’s this same case/when done with if’s:
<pre class="brush:ruby">if 1..18 === age
  puts 'just out of college'
elsif 19..30 === age
  puts 'wild years'
elsif 31..40 === age
  puts 'i better find a job in a big corp'
else
  puts 'retirement plan'
end</pre>
In the end, the case/when statement is just a glorified if using the ‘===’ operator to simplify your job (and also make you type less). In the language itself, the triple equals is used mostly to as a “grouping” operator, by getting a value and figuring out at which group it belongs to.

In our example it’s a group of ages represented by Range objects, but you’ll see this being used to figure out if an object is from an specific class, if a string matches a regular expression and the like. And all of this is possible because the method (‘===’) is not called at the object in the “case” definition but on each “when”.

Imagine you have Rectangles and you want to figure out if a specific Point is inside the Rectangle, this is a perfect fit for the triple equals. Let’s look at a sample implementation:
<pre class="brush:ruby">class Point

  include Comparable

  attr_accessor :x, :y

  def initialize(x, y)
    self.x = x
    self.y = y
  end

  def hash
    "#{x}-#{y}".hash
  end

  def &lt;=&gt; (other)

    result = nil

    if other.respond_to?(:x) &amp;&amp; other.respond_to?(:y)

      result = if self.x == other.x &amp;&amp; self.y == other.y
                 0
               elsif self.x &gt;= other.x &amp;&amp; self.y &gt;= other.y
                 1
               else
                 -1
               end

    end

    result

  end

end</pre>
And the Rectangle class:
<pre class="brush:ruby">class Rectangle

  attr_accessor :start, :end

  def initialize( x1, y1, x2, y2 )
    self.start = Point.new( x1, y1 )
    self.end = Point.new( x2, y2 )

    if self.start &gt;= self.end
      raise "Start #{self.start.inspect} should be less than end #{self.end.inspect}"
    end
  end

  def === (other)
    if other.respond_to?(:x) &amp;&amp; other.respond_to?( :y )
       other.between?( self.start, self.end )
    else
      self == other
    end
  end

  def == (other)
    if other.respond_to?( :start ) &amp;&amp; other.respond_to?( :end )
      self.start == other.start &amp;&amp; self.end == other.end
    end
  end

end</pre>
And now some usage:
<pre class="brush:ruby">point = Point.new( 2, 4 )

case point
  when Rectangle.new( 0, 3, 5, 8  )
    puts 'found it here'
  when Rectangle.new( 3, 3, 10, 15  )
    puts 'i will not match'
end</pre>
The ‘===’ method will be called on Rectangle giving it a Point object and it’s going to figure out if that point is inside the Rectangle or not.
<h2>Making your objects Comparable</h2>
If you looked closely at the Point object you will notice that it includes the Comparable module and implements a method defined as “&lt;=&gt;”, the flying saucer operator. The flying saucer operator is to be used as means to sort your objects in a collection, but the Comparable module brings some interesting functionality for classes that implement it.

The idea behind the “&lt;=&gt;” operator is that when you call it on a object, this object must define it’s position compared to the other object given as a parameter. If the receiver of the call is greater than the argument, it should return 1, if they re the same, it should return 0, if the receiver is less than the argument it should return -1 and if they’re not compatible it should return nil.

Once you implement the flying saucer, you can just include Comparable in your class and the following methods are now implemented for you:
<ul>
	<li>&gt;</li>
	<li>&gt;=</li>
	<li>&lt;</li>
	<li>&lt;=</li>
	<li>==</li>
	<li>between?</li>
</ul>
This is why we could use the “between?” method in Point when implementing the “===” operator on Rectangle. By implementing “&lt;=&gt;” and including Comparable we get a lot of functionality for our objects for free and we also have a great example of how you should plan to build your own modules on your projects.

Going back to our first example, the Meter class, we could add new classes for Inch and Foot and have them all share the same equality implementation. First, we define that all our classes will have a to_meters method that will return their value in meters. Then we create our module:
<pre class="brush:ruby">module MeterComparator

  include Comparable

  def &lt;=&gt; (other)
    result = nil

    if other.respond_to?(:to_meters)
      receiver_value = self.to_meters
      argument_value = other.to_meters

      result = if receiver_value == argument_value
                 0
               elsif receiver_value &lt; argument_value
                 -1
               else
                 1
               end
    end

    result
  end

  def inspect
    "#&lt;#{self.class}:#{self.hash} size_in_meters=#{self.to_meters}&gt;"
  end

  def hash
    self.to_meters.hash
  end

end</pre>
We implemented the “&lt;=&gt;” operator and (also the “hash” method, don’t forget it!) for this module and included Comparable, which will make all classes including it to be comparable too. Let’s look at how our new Meter, Inch and Foot will look like now:
<pre class="brush:ruby">class Meter

  include MeterComparator

  def initialize( value )
    @value = value
  end

  def to_meters
    @value.to_f
  end

end</pre>
And Inch:
<pre class="brush:ruby">class Inch

  include MeterComparator

  def initialize( value )
    @value = value
  end

  def to_meters
    @value.to_f / 39.370
  end

end</pre>

And finally Foot:

<pre class="brush:ruby">class Foot

  include MeterComparator

  def initialize( value )
    @value = value
  end

  def to_meters
    @value.to_f / 3.2808
  end

end</pre>

All classes share the same comparison methods so we can use them all interchangeably in our code, we can even safely compare them with each other and they’ll yield the correct results:

<pre class="brush:ruby">  context 'comparing meters with inches' do

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

  end</pre>

You can mix and mingle different measures and they’ll all play and compare nicely to each other, they just have to implement the “to_meters” method and include the MeterComparator class, simple and right to the point implementation.

Also, once you include the Comparable module your objects become "sortable" in an array, you can use the "sort" and "sort!" methods in Array. The order is ascending as defined by your "<=>" method implementation.

<h2>“eql?” and “equal?”</h2>

Technically, “eql?” is should behave just like “==” and it's also the method selected by the <strong>Hash</strong> class to figure out of your object is already in a "hash cluster" (as we have discussed above). You compare two objects to see if they represent the same values. Usually you can just override "eql?" and delegate it's call to "==", as we did in our examples. <strong>This is not already done for you</strong>, the default "eql?" implementation at the <strong>Object</strong> class uses comparison between "object_id" values and this is usually <strong>NOT</strong> what you want, so, make sure that if you implement "==" you also override "eql?" and implement "hash".

There’s one exception, though, Numeric objects will convert different types when compared using “==” but will not do this when using “eql?”, so:

<pre class="brush:ruby">5 == 5.0 # is true</pre>

But:

<pre class="brush:ruby">5.eql?( 5.0 ) # is false</pre>

And “equal?” is a little bit exoteric as it will compare if two objects are the same object in memory. You should never ever override this method. In fact, you’re better of ignoring the fact that “equal?” exist at all for your own safety. And don’t say you have not been warned.

<h2>Closing thoughts</h2>

While there’s a lot to be said about comparing objects in Ruby, the final implementation is quite simple and modules like Comparable make it even simpler as long as you know they exist. Now there’s no reason to correctly implement comparison for your Ruby objects and never forget the “hash” method again! ;)

<h2>Want to dig deeper into Ruby?</h2>

Here are some books that will surely help you out:

<ul>
<li><a href="http://www.amazon.com/gp/product/0321584104/ref=as_li_ss_tl?ie=UTF8&tag=techbot-20&linkCode=as2&camp=217145&creative=399349&creativeASIN=0321584104">Eloquent Ruby (Addison-Wesley Professional Ruby Series)</a><img src="http://www.assoc-amazon.com/e/ir?t=&l=as2&o=1&a=0321584104&camp=217145&creative=399349" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />
</li>
<li>
<a href="http://www.amazon.com/gp/product/0321490452/ref=as_li_ss_tl?ie=UTF8&tag=techbot-20&linkCode=as2&camp=217145&creative=399349&creativeASIN=0321490452">Design Patterns in Ruby</a><img src="http://www.assoc-amazon.com/e/ir?t=&l=as2&o=1&a=0321490452&camp=217145&creative=399349" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />
</li>
<li>
<a href="http://www.amazon.com/gp/product/1933988657/ref=as_li_ss_tl?ie=UTF8&tag=techbot-20&linkCode=as2&camp=217145&creative=399349&creativeASIN=1933988657">The Well-Grounded Rubyist</a><img src="http://www.assoc-amazon.com/e/ir?t=&l=as2&o=1&a=1933988657&camp=217145&creative=399349" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />
</li>
</ul>

<h2>Related Posts</h2>

<ul>
  <li><a href="http://techbot.me/2009/06/understanding-class_eval-module_eval-and-instance_eval/">Understanding class_eval, module_eval and instance_eval</a></li>
  <li><a href="http://techbot.me/2008/09/including-and-extending-modules-in-ruby/">Including and extending modules in Ruby</a></li>
</ul>
