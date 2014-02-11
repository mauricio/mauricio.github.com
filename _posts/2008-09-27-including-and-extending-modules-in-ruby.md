---
layout: post
title: Including and extending modules in Ruby
tags:
- object orientation
- rails
- ruby
- ruby-basics
- useful
---

One of the coolest features in Ruby is the existence of modules and the possibility of including their implementation in any object. This simple behavior is the source of things like the [Enumerable](http://www.ruby-doc.org/core/classes/Enumerable.html) module, that gives you a bunch of methods to work with a collection of objects and just expects that the class that included it to define an “each” method. You write a class, define an “each” method, include Enumerable and your're done, all Enumerable methods are available for you.

Another example is the [Comparable](http://www.ruby-doc.org/core/classes/Comparable.html) module, when you include the Comparable module in your class, you must define the  operator (the [UFO](http://en.wikipedia.org/wiki/UFO) operator), the Comparable module will give you the implementation of the following operators/methods:

{% highlight ruby %}
<, <=, >, >=, ==, between?
{% endhighlight %}

This is usually why we call them mixins, because they are “mixing in” their behaviors (their methods/messages) into our objects. The idea of mixins serve a purpose similar to that of the multiple inheritance, that is to inherit an implementation from “something” without having to be a direct child of that “something”, in multiple inheritance you would be able to inherit from as many classes as you wanted to. In Ruby we don't have multiple inheritance, but we can include as many modules as we want, so they give us the same feature, without all the hassle that multiple inheritance usually brings to a language.

The method resolution mechanism is pretty simple, first, if a method in a module that is being included is already defined in the class that is including it, the method of the class has precedence (which means that the method on the module will be ignored). If two modules define a method with the same name, the method on the last module included will be the one available at the class that has included both modules (remember that in Ruby there is no method overloading mechanism). Here's an example of how it works:

{% highlight ruby %}
module SimpleModule

  def a_method
    puts 'a_method at module'
  end

  def another_method( parameter )
    puts "Calling another method with parameter -&gt; #{parameter}"
  end

end

module AnotherModule

  def another_method
    puts 'Calling another method without a parameter'
  end

end

class SimpleClass

  include SimpleModule
  include AnotherModule

  def a_method( param )
    puts "a_method at class -&gt; #{param}"
  end

end

instance = SimpleClass.new

#calling the method defined on the class
instance.a_method 'parameter'

#calling method on the AnotherModule
instance.another_method

#this line will throw a 'wrong number of arguments' error
instance.a_method
{% endhighlight %}

An ugly example for an ugly practice, don't rely on these things when you're writing your own modules, strive to create unique modules that aren't going to have method names clashing when they are included in other classes. If you have to rely on these rules to write and use your modules, maybe there is a problem in your code or in what you're trying to do.

## Extending methods

As the title of this post says, you can include and also extend modules, but what does it means to extend a module?

When you extend a module, you are adding the methods of that specific module into the object instance you call “extend”. So, the methods of that module will only be available at that specific instance (and not all objects of that class), other objects of the same class will not have the methods of the module available. With this, you can add specific behaviors to just one object of your system, without changing the other ones. Here's an example:

{% highlight ruby %}
module InstanceMethods

  def simple_method
    puts "im a method that belongs to an instance"
  end

end

class SimpleObject
end

object = SimpleObject.new
object.extend InstanceMethods
object.simple_method

another_object = SimpleObject.new

#the following line will throw an error, as this instance doesn't extends the module
another_object.simple_method
{% endhighlight %}

This might look like a weird feature, how many times have you wanted to introduce a method into a single object?

Not that many, probably, unless this instance is in fact an instance of the Class class (that contains the class methods of your object), and this is where extending modules get interesting and this is how many of the Rails plugins are written, let's see how we can use this to write our own acts_as_votable plugin.

## Rails, extending and including modules

First thing to do is create your Rails project:

{% highlight bash %}
rails --database=mysql include_extend_modules
{% endhighlight %}

With the project created, we have to create our plugin (enter in your Rails project folder):

{% highlight bash %}
script/generate plugin acts_as_votable
{% endhighlight %}

This will create a folder called acts_as_votable at the vendor/plugins folder and the plugin skeleton code. The first thing to do is to create our Vote model. It's a dead simple model, with a polymorphic relationship with a “votable” and a boolean column called “up”, representing if this vote is “up” or “down”. The vote.rb file should live at the vendor/plugins/acts_as_votable/lib folder. Here's the model code:

{% highlight ruby %}
#vendor/plugins/acts_as_votable/lib/vote.rb

class Vote < ActiveRecord::Base
  belongs_to :votable, :polymorphic => true
  validates_presence_of :votable
end
{% endhighlight %}

Now we have to create a migration to create the votes table at the database:

{% highlight bash %}
script/generate migration create_votes
{% endhighlight %}

And there is the migration code:

{% highlight ruby %}
class CreateVotes < ActiveRecord::Migration
  def self.up

    create_table :votes do |t|
      t.integer :votable_id, :null => false
      t.string :votable_type, :limit => 15, :null => false
      t.boolean :up, :default => false, :null => false
      t.timestamps
    end

    add_index :votes, [ :votable_id, :votable_type ]

  end

  def self.down

    drop_table :votes

  end
end
{% endhighlight %}

After creating the Vote model and it's migration, we'll head to that acts_as_votable.rb file in our plugin folder, it's where the code that ties the Vote model with the application will live, here's the code that will be in there:

{% highlight ruby %}
#vendor/plugins/acts_as_votable/lib/acts_as_votable.rb

module ActsAsVotable

  module ClassMethods

    def acts_as_votable
      has_many :votes, :as => :votable, :dependent => :delete_all
      include InstanceMethods
    end

  end

  module InstanceMethods

    def cast_vote( vote )
      Vote.create( :votable => self, :up => vote == :up )
    end

  end

end
{% endhighlight %}

We have created a module called ActsAsVotable to serve as our namespace and in it we have two modules ClassMethods and InstanceMethods. The ClassMethods module defines the methods that we want to introduce at the ActiveRecord::Base class, so that we can just call “acts_as_votable” in any model that inherits from ActiveRecord::Base (just like any other ActiveRecord plugin) and the InstanceMethods module contains the methods that we want an instance that is “votable” to have.

So, if I say that a NewsArticle class is votable, its instances will have the cast_vote method, as the module InstanceMethods was included when they called acts_as_votable. But before creating the NewsArticle model, we have to do some changes in our init.rb file for the acts_as_votable plugin, here's how it should look like:

{% highlight ruby %}
#vendor/plugins/acts_as_votable/init.rb

require 'vote'
require 'acts_as_votable'

ActiveRecord::Base.extend ActsAsVotable::ClassMethods
{% endhighlight %}

This is where we make the acts_as_votable method available to all classes that inherit from ActiveRecord::Base and this is one of the most common uses of “extending” modules you will see.

Now that we have the code hooked to ActiveRecord, let's create a simple model to try some tests, create our NewsArticle model:

{% highlight bash %}
script/generate model NewsArticle title:string article:text
{% endhighlight %}

Now, at the news_article.rb file:

{% highlight ruby %}
#app/models/news_article.rb

class NewsArticle < ActiveRecord::Base

  acts_as_votable
  validates_presence_of :title, :article

end
{% endhighlight %}

We just call the acts_as_votable class method, that is available as we “exetended” the ActsAsVotable::ClassMethods module into the ActiveRecord::Base class, the superclass of our NewsArticle class. Here's an example of you could do with our models:

{% highlight ruby %}
article = NewsArticle.create(:title => 'sample', :article => 'sample')

#calling the cast_vote method from the ActsAsVotable::InstanceMethods module
article.cast_vote :up
article.cast_vote :down

#acessing the votes association defined when you called the acts_as_votable method
article.votes
{% endhighlight %}

And that's it, you now know how and when to include or extend modules and even how to build a simple acts_as plugin for your models.