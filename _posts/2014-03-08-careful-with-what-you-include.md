---
layout: post
title: Public methods are your public API
subtitle: and you should be careful with what you include
keywords: ruby, include, extend, public apis, methods, composition, delegation, inheritance
tags:
- ruby
- useful
---

I was reading [Public Methods != Public API](http://www.collectiveidea.com/blog/archives/2014/02/19/public-methods-public-api/) and it didn't really ring to me. The example itself is nice and it makes sense not to assume all public methods are part of your object's public API but this isn't what actually happens in the real world. If you use Ruby's Enumerable frequently, you frequently use methods like `map` and `inject`, if any of these methods is renamed to something else or is removed, you will have a hard time.

If you lived through Rails 1.x and 2.x you know this by heart. Most gems were monkeypatching Rails in weird ways to include new features, even Rails itself used this throughout it's own codebase to implement higher level abstractions like dirty-tracking for `ActiveRecord` objects (`alias_method_chain` anyone?). Whenever a new version was published, gems would break and we'd have to go hunting for newer versions of our monkeypatches and hope a hook would come up to save us from all this madness.

Every method that can be seen will be called, no matter what, telling people that __you should not call this, it's not part of the public api__ has very little value, specially because the __code__ itself isn't saying this. It will probably be embedded in some kind of documentation and that's actually not the place for this. Actually, even if the method isn't public per se, it shouldn't be there as well:

<blockquote class="twitter-tweet" lang="en" align="center"><p>I almost declared a method private, but then I realized that was the code telling me I needed a new class. Much better result.</p>&mdash; Herr Fauler (@chadfowler) <a href="https://twitter.com/chadfowler/statuses/440604666376642561">March 3, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

While this might seem fatalistic and exaggerated, it's hard to see cases where this doesn't apply. When you declare a method private, it usually means you don't want people that are using __that specific object__ to see that method. It doesn't mean you don't want __everyone__ from being able to see it, it's just that you think whoever is using this object doesn't need to know about it.

But this current object needs to know about this method, so this method is a __public API__ that someone needs to have access to. And that's why most of the time when this happens what you want is another object to do the job. And with this we circle back to the beginning, while everything that can be called will be called, if is isn't part of the current object, it isn't part of it's public API because you can't call it directly. The new level of indirection hides the method from people sending messages to your object.

One advice I always try to keep close to me when building APIs is [this from Joshua Block](http://www.infoq.com/articles/API-Design-Joshua-Bloch):

> When in doubt, leave it out. If there is a fundamental theorem of API design, this is it. It applies equally to functionality, classes, methods, and parameters. Every facet of an API should be as small as possible, but no smaller. You can always add things later, but you can't take them away. Minimizing conceptual weight is more important than class- or method-count.

Once it's out there, people will be using it and it's hard to go back. Hard for who wrote the API, since they will have to maintain or alienate users and hard on users as well since this means they will have to revisit code that was actually working just to honor the new API that is different now.

## Careful with what you include

Still in the same vein of public APIs, comes another problem that is more common in dynamic languages like Ruby. When you inherit from or include something in your class/module you're not taking only what's directly in what you're including/extending, you're taking everything that that object extends/includes as well.

In a language like Ruby, where you can't easily know at development time all methods that will be included into your object when you inherit/include something so you end up with weird to figure out errors due to methods defined in superclasses/modules you didn't even know existed.

One of such examples is the [process](https://github.com/mongoid/mongoid/blob/2.8.0-stable/lib/mongoid/attributes/processing.rb#L21) method defined at `Mongoid::Attributes::Processing` (this was `mongoid` 2.x). We had no idea there was a `process` method defined somewhere in `mongoid` and defined it in our own object. Since this method isn't called in all code paths, the code worked in some cases and didn't in others. Figuring out what was going on took some debugging and testing time. `process` itsef is a rather common method, Rails controllers themselves [couldn't have an action called `process`](http://stackoverflow.com/questions/11021800/why-rails-controller-action-method-requires-parameter) since this method was used by `ActionPack` to send requests to controllers as well.

So, not only it's important to be careful on what you expose as the public API for your objects that will be consumed but it's also important to consider what will happen with your classes/modules when they get included into other objects. Will it be like `ActiveRecord::Base` that includes a couple hundred methods at the included objects? Is it really necessary? Could we move this logic somewhere else?

Most of the time, you can. One of these days we wanted to include feature flagging to accounts in the system. The first idea was declaring the methods right at the `Account` object itself so we could do stuff like:

{% highlight ruby %}
account.feature_visible?(:some_feature)
account.show_feature!(:some_other_feature)
account.hide_feature!(:main_feature)
{% endhighlight %}

But then `account.rb` was already big and this code would be used only in some very specific pieces in the system, why not move it somewhere else?

The actual implementation had features that would be enabled system-wide and that could also be enabled only for an specific account. Since we were using `MongoDB`, the list of features enabled for the account alone became an array at the `Account` class and the others lived at their own `FeatureFlag` records, so we needed a solution that had access to the account document and that could search for the `FeatureFlag` objects as well.

We ended up creating the `FeatureFlagging::FeaturesCollection` object for it:

{% highlight ruby %}
module FeatureFlagging
  class FeaturesCollection

    def initialize(account)
      @account = account
    end

    def visible?(name)
      features.include?(name) || FeatureFlag.visible?(name, @account)
    end

    def show!(name)
      self.features = self.features + [name]
    end

    def hide!(name)
      self.features = self.features - [name]
    end

    def features
      @account.features_enabled || []
    end

    def features=(list)
      @account.features_enabled = list.flatten.uniq
      @account.save!
    end

  end
end
{% endhighlight %}

And so here we have all methods we need so far to check for features visible or not. Now, we have to hook it somewhere and this somewhere will be the account object itself. Here's how it looks:

{% highlight ruby %}
def features
  @features ||= FeatureFlagging::FeaturesCollection.new(self)
end
{% endhighlight %}

And this allows me to use code as:

{% highlight ruby %}
account.features.visible?(:some_feature)
account.features.show!(:some_feature)
account.features.hide!(:some_feature)
{% endhighlight %}

Not much of a difference from the original one, is there?

There are two main differences here, the code that does all the feature flagging is now __somewhere else__ and not at the account object. It doesn't even have to use an account, any object with a `features_enabled` collection and a `save` method would do it, so this could be reused in other places/parts of the code as long as the __public interface__ is maintained. This makes it simpler to test and to validate what is going on.

The other difference is that we didn't pollute the `Account` object with the feature-related methods. Right now, we only have these 3 specific methods, but they might grow and, more importantly, they're not inside the already large `Account` class, not even by including a module, they're just not part of it in __any__ way.

## Classic OOP

There's no magic here, this is the classic [prefer composition over inheritance](http://en.wikipedia.org/wiki/Composition_over_inheritance) we see so often out there but don't practice that much. Using composition in this case now only allows us to slim our `Account` object but simplifies testing the `FeatureFlagging::FeaturesCollection` object and allows us to include more methods there as we see fit without getting too worried if these methods will clash with someone or something.

Now let me get back to my codebase and fix all cases of this there as well :D