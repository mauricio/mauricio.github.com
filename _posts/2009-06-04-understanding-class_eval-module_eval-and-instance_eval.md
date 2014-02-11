---
layout: post
title: Understanding class_eval, module_eval and instance_eval
tags:
- useful
---

Most of Ruby’s fame is due to it’s dynamic capabilities. In Ruby you can define and redefine methods at runtime, create classes from nowhere and objects from pure dust. Most of these dynamical features are done using one of those methods at the title, class_eval, module_eval and instance_eval, they’re usually the ones responsible for the show and now we’re going to learn a little bit about how they work and how we could use them in our objects.

## class_eval and module_eval

These two methods are responsible to granting your access to a class or module definition, as if you were writing their code by yourself. When you do something like this:

{% highlight ruby %}
Dog.class_eval do
    def bark
        puts “Huf! Huf! Huf!”
    end
end
{% endhighlight %}

It’s almost the same as doing this:

{% highlight ruby %}
class Dog
    def bark
        puts “Huf! Huf! Huf!”
    end
end
{% endhighlight %}

What’s the difference?

With the class_eval you’re adding a method to a pre-existing class. If a class called Dog is not defined before our class_eval runs you’d see an “NameError: uninitialized constant Dog”. A class_eval call opens up an existing class for you, it won’t create or open a class that doesn’t exist yet.

And you don’t need to always write real code inside your class_eval calls, you can also send a string object containing the code you want to have ‘evaled inside your class. Let’s see how we could define a macro just like the attr_accessor using class_eval’ed strings:

{% highlight ruby %}
Object.class_eval do

  class << self

    def attribute_accessor( *attribute_names )

      attribute_names.each do |attribute_name|
        class_eval %Q?
          def #{attribute_name}
              @#{attribute_name}
          end

          def #{attribute_name}=( new_value )
              @#{attribute_name} = new_value
          end
        ?
      end

    end

  end

end

class Dog
  attribute_accessor :name
end

dog = Dog.new
dog.name = 'Fido'

other_dog = Dog.new
other_dog.name = 'Dido'

puts dog.name
puts other_dog.name
{% endhighlight %}

As you can see, we used both kinds of class_eval. First we opened up the Object class and added a new class method called attribute_accessor with direct code, but then, at the attribute_acessor I had no way to figure out the method name when I was writing the code, so, instead of just writing the code directly inside the class_eval call I’ve created a string object containing the code that I wanted to have ‘evaled by the class_eval method. The string is then turned into something like this:

{% highlight ruby %}
def name
    @name
end

def name=( new_value )
    @name = new_value
end
{% endhighlight %}

And this is the parameter passed on to the class_eval call. Wrapping up, you can use class_eval to open classes (and modules) and add real code on it as you also can just pass a string containing valid Ruby code and it’s going to be ‘evaled as it was at the class definition body.

The module_eval method is just an alias to class_eval so you can use them both for classes and modules.

The instance_eval method works just like class_eval but it will add the behavior you’re trying to define to the object instance where it was called.

But hey, isn’t this exactly what we were doing with class_eval?

No, it isn’t. With class_eval we opened up a class definition and added code to it’s body. Any kind of code valid inside a class definition was also valid in there. When we’re using instance_eval the rules change a bit ‘cos we’re not opening up a class, but a single object instance.

How’s that? Let’s see an example:

{% highlight ruby %}
class Dog
  attribute_accessor :name
end

dog = Dog.new
dog.name = 'Fido'

dog.instance_eval do
    #here I am defining a bark method only for this “dog” instance and not for the Dog class
  def bark
   puts 'Huf! Huf! Huf!'
  end

end

other_dog = Dog.new
other_dog.name = 'Dido'

puts dog.name
puts other_dog.name

dog.bark
other_dog.bark #this line will raise a NoMethodError as there’s no “bark” method
                      #at this other_dog object
{% endhighlight %}

Not really that interesting, is it? We can also use instance_eval to define methods in Class objects (which in turn will be class methods at that Class object instances) and we can do just that to our attribute_accessor:

{% highlight ruby %}
Object.instance_eval do

  def attribute_accessor( *attribute_names )

    attribute_names.each do |attribute_name|
      class_eval %Q?
          def #{attribute_name}
              @#{attribute_name}
          end

          def #{attribute_name}=( new_value )
              @#{attribute_name} = new_value
          end
      ?
    end

  end

end
{% endhighlight %}

By using instance_eval instead of class_eval we don’t need the “class << self” as the method is defined directly at the Object class and will then be available as a class method for Object instances and Object subclasses instances.

As you might have noticed, [these methods are also related to the difference between including and extending modules in Ruby](/2008/09/27/including-and-extending-modules-in-ruby.html).
