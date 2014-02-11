---
layout: post
title: Building your own ActiveRecord validation macros with validates_each
tags:
- outdated
---
A common task when writing your own Rails applications using ActiveRecord is creating your own validations for your models. While it’s perfectly correct to add the validation directly into the model you’re going to need it, sometimes you’d like to reuse the same validation logic  in other models and we’re not really going to do a cut-and-paste here are we?

<!--more-->

The simplest solution when you’re validating fields (and not the whole model) is to use the validates_each method, as it has some nice features seen in other validations that might interest you as the :if, :unless, :allow_blank and :allow_nil options.

Our custom example validation is to validate that one or more fields are different from one specific field. Imagine that you’re building an invoices application, having the seller to also be the buyer isn’t really what you’re looking for, so that’s why we’re building this validation. Let’s take a look at the validation code:

<pre class="brush:ruby">ActiveRecord::Base.class_eval do

  def self.validates_different( *args )

    options = args.extract_options!
    raise &quot;You must define a :field option to compare to&quot; if options[:field].blank?

    validates_each(*(args &lt;&lt; options)) do |record, attribute, value|
      if record.send( options[:field] ) == value
        record.errors.add(
          attribute,
          record.errors.generate_message(
            attribute
            'different',
            :field =&gt; record.class.human_attribute_name( options[:field].to_s ) ) )
      end
      true
    end

  end

end</pre>

We have inserted a static method inside the ActiveRecord::Base class to be our validation macro, it takes a list of parameters and an options hash at the end, here’s a sample of how it would be used:

<pre class="brush:ruby">class Invoice &lt; ActiveRecord::Base
    validates_different :seller_id, :field =&gt; :buyer_id, :allow_blank =&gt; true
end</pre>

The validation looks just like any other ActiveRecord validation and even uses options well known in them like :allow_blank, keeping the principle of least surprise at bay. It’s also important to notice the use of I18N on the validation message, the “'activerecord.errors.messages” namespace is the ActiveRecord error messages namespace and that’s where you should add your custom validation messages, do not place the messages directly inside your validation or model code. Here’s how the YAML file would look like:

<pre><code>en:
  activerecord:
    errors:
      messages:
        different: “must be different than {{field}}”</code></pre>

And there you go, you have built your own validation macro for your ActiveRecord models and even used the I18N helpers to keep the messages away from your model code.
