---
layout: post
title: Understanding class_eval, module_eval and instance_eval
tags:
- en_US
- metaprogramming
- reflection
- ruby
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  delicious: s:78:"a:3:{s:5:"count";s:1:"1";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1280621456";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1282223616";}";
  dsq_thread_id: '217521038'
  _su_keywords: ruby, rails, class_eval, module_eval, instance_eval, metaprogramming,
    reflection, code generation, runtime improvements
  _su_description: Metaprogramming and reflection are two things that every single
    programmer should learn to improve his skills in the craft.
  _su_rich_snippet_type: none
  _su_title: Understanding class_eval, module_eval and instance_eval
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"1";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"1";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"1";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:3;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"1";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"1";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"1";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:6;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"1";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:7;a:4:{s:2:"ID";s:2:"59";s:10:"post_title";s:150:"Setting
    up your Ruby on Rails application in an Ubuntu Jaunty Jackalope (9.04) server
    with Nginx, MySQL, Ruby Enterprise Edition and Phusion Passenger";s:7:"matches";s:1:"1";s:9:"permalink";s:172:"http://techbot.me/2009/06/setting-up-your-ruby-on-rails-application-in-a-ubuntu-jaunty-jackalope-9-04-server-with-nginx-mysql-ruby-enterprise-edition-and-phusion-passenger/";}i:8;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"1";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:9;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"1";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}}
  _relation_threshold: '1'
---
[caption id="attachment_160" align="alignleft" width="122" caption="Dig deeper into Ruby with this book"]<a href="http://www.amazon.com/gp/product/0596516177?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=0596516177"><img src="http://techbot.me/wp-content/uploads/2011/01/ruby1.jpg" alt="Dig deeper into Ruby with this book" title="Dig deeper into Ruby with this book" width="122" height="160" class="size-full wp-image-160" /></a>[/caption]Most of Ruby’s fame is due to it’s dynamic capabilities. In Ruby you can define and redefine methods at runtime, create classes from nowhere and objects from pure dust. Most of these dynamical features are done using one of those methods at the title, class_eval, module_eval and instance_eval, they’re usually the ones responsible for the show and now we’re going to learn a little bit about how they work and how we could use them in our objects.

<h3>class_eval and module_eval</h3>

These two methods are responsible to granting your access to a class or module definition, as if you were writing their code by yourself. When you do something like this:

<pre class="brush:ruby">Dog.class_eval do
    def bark
        puts “Huf! Huf! Huf!”
    end
end</pre>

It’s almost the same as doing this:

<pre class="brush:ruby">class Dog
    def bark
        puts “Huf! Huf! Huf!”
    end
end</pre>

What’s the difference?

With the class_eval you’re adding a method to a pre-existing class. If a class called Dog is not defined before our class_eval runs you’d see an “NameError: uninitialized constant Dog”. A class_eval call opens up an existing class for you, it won’t create or open a class that doesn’t exist yet.

And you don’t need to always write real code inside your class_eval calls, you can also send a string object containing the code you want to have ‘evaled inside your class. Let’s see how we could define a macro just like the attr_accessor using class_eval’ed strings:

<pre class="brush:ruby">Object.class_eval do

  class &lt; &lt; self

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
puts other_dog.name</pre>

As you can see, we used both kinds of class_eval. First we opened up the Object class and added a new class method called attribute_accessor with direct code, but then, at the attribute_acessor I had no way to figure out the method name when I was writing the code, so, instead of just writing the code directly inside the class_eval call I’ve created a string object containing the code that I wanted to have ‘evaled by the class_eval method. The string is then turned into something like this:

<pre class="brush:plain">def name
    @name
end

def name=( new_value )
    @name = new_value
end</pre>

And this is the parameter passed on to the class_eval call. Wrapping up, you can use class_eval to open classes (and modules) and add real code on it as you also can just pass a string containing valid Ruby code and it’s going to be ‘evaled as it was at the class definition body.

The module_eval method is just an alias to class_eval so you can use them both for classes and modules.

The instance_eval method works just like class_eval but it will add the behavior you’re trying to define to the object instance where it was called.

But hey, isn’t this exactly what we were doing with class_eval?

No, it isn’t. With class_eval we opened up a class definition and added code to it’s body. Any kind of code valid inside a class definition was also valid in there. When we’re using instance_eval the rules change a bit ‘cos we’re not opening up a class, but a single object instance.

How’s that? Let’s see an example:

<pre class="brush:plain">class Dog
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
                      #at this other_dog object</pre>

Not really that interesting, is it? We can also use instance_eval to define methods in Class objects (which in turn will be class methods at that Class object instances) and we can do just that to our attribute_accessor:

<pre class="brush:ruby">Object.instance_eval do

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

end</pre>

By using instance_eval instead of class_eval we don’t need the “class &lt;&lt; self” as the method is defined directly at the Object class and will then be available as a class method for Object instances and Object subclasses instances.

As you might have noticed, <a href="http://codeshooter.wordpress.com/2008/09/27/including-and-extending-modules-in-ruby/">these methods are also related to the difference between including and extending modules in Ruby.</a>
