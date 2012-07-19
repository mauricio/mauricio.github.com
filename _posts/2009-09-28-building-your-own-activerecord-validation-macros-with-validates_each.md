---
layout: post
title: Building your own ActiveRecord validation macros with validates_each
tags:
- activerecord
- en_US
- rails
- ruby
- ruby on rails
- validations
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  delicious: s:78:"a:3:{s:5:"count";s:1:"1";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1281482612";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1295404658";}";
  dsq_thread_id: '217521088'
  _su_keywords: ''
  _su_description: ''
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:3;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:6;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:7;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
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
