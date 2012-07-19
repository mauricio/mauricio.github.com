---
layout: post
title: Building a I18N aware form builder for your Rails applications
tags:
- en_US
- form builder
- i18n
- rails
- ruby
- ruby on rails
- Tutorials
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1294863757";}";
  delicious: s:78:"a:3:{s:5:"count";s:1:"7";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1280621453";}";
  dsq_thread_id: '218404264'
  _su_keywords: ''
  _su_description: ''
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"134";s:10:"post_title";s:50:"Full
    text search in in Rails with Sunspot and Solr";s:7:"matches";s:1:"2";s:9:"permalink";s:77:"http://techbot.me/2011/01/full-text-search-in-in-rails-with-sunspot-and-solr/";}i:3;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:4;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:5;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:6;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:7;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
---
Form builders are one of the coolest features when building Rails applications, they streamline the task of writing complex forms and you can usually write your own form builder to maintain their consistency in your application. One of the most common customized form builders is the one that users the field name to show a label:

<pre class="brush:plain">&lt; % form_for @user, :builder =&gt; SimpleFormBuilder do |f| %&gt;
    &lt; %= f.text_field :date_of_birth %&gt;
&lt; % end %&gt;</pre>
We would probably use the “date_of_birth” symbol, turn it into a String and then call “humanize” on it ( you can see a custom form builder example that does exactly this <a href="http://onrails.org/articles/2008/06/13/advanced-rails-studio-custom-form-builder">here</a> ):
<pre class="brush:plain">:date_of_birth.to_s.humanize
=&gt; “Date of birth”</pre>

That’s awesome if you’re building a website for a language that uses only ASCII characters, but if you’re building a form in Portuguese you’re doomed. Imagine that my “usuario” (user) has a “profissão” (profession) and I try to use it using a common form builder:

<pre class="brush:plain">&lt; % form_for @usuario, :builder =&gt; SimpleFormBuilder do |f| %&gt;
    &lt; %= f.text_field :profissao %&gt;
&lt; % end %&gt;</pre>

What do I get? “profissao”, no tilde. And if I try to create a method called “profissão” at my object it’s just going to break.

So, customized form builders for Rails using funny characters are impossible? Never! With the new I18N support this trouble as been completely removed, let’s see how we can write a customized form builder that uses the attribute names to generate labels and will respect funny Portuguese, Russian or characters from any other language.

Here’s the builder code:

<pre class="brush:ruby">class SimpleFormBuilder &lt; ActionView::Helpers::FormBuilder

  attr_accessor :object_class

  helpers = field_helpers +
            %w{date_select datetime_select time_select} +
            %w{collection_select select country_select time_zone_select} -
            %w{hidden_field label fields_for submit select} # Don't decorate these

  helpers.each do |name|
    class_eval %Q!
    def #{name}(field, *args)
      options = args.extract_options\!
      args &lt;&lt; options
      return super if options.delete(:disable_builder)
      @template.content_tag(:p, field_label(field, options) &lt;&lt; '' &lt; &lt; super)
    end
    !
  end

  def select(field, choices, options = {}, html_options = {})
    return super if options.delete(:disable_builder) || html_options.delete(:disable_builder)
    @template.content_tag(:p, [field_label(field, options), '', super].join("\n"))
  end

  def submit(value = nil, options = {})
    if self.object &amp;&amp; value.nil?
      value = self.object.new_record? ? I18n.t( 'txt.shared.create' ) : I18n.t( 'txt.shared.update' )
    end
    @template.content_tag( :p, super( value, options ) )
  end

  def field_label( field, options )
    self.label( field, options.delete( :label ) || self.object_class.human_attribute_name( field.to_s ), :class =&gt; options[:label_class])
  end

  def initialize(object_name, object, template, options, proc)
    super
    self.object_class = self.object.nil? ? self.object_name.to_s.camelize.constantize : self.object.class
  end

end</pre>

We’ve created our own form builder that inherits from the ActionView::Helpers::FormBuilder and it redefines all field helpers using a class_eval call (don’t know what class_eval does? <a href="http://codeshooter.wordpress.com/2009/06/04/understanding-class_eval-module_eval-and-instance_eval/">Learn here</a>).

Our version isn’t really that different from the usual solution, it looks for a :disable_builder option, if there’s one and it’s true, the builder will just call the original method, without the custom decoration. If there’s no :disable_builder option the builder will set out to do its work. Also, we need the object class to find out the correct attribute names, so your form builder also holds the class of the object that’s being used in the form.

If there’s a :label option available, it’s the one that’s going to be used, if there’s no :label option the builder will access the class of the object that’s being used in the form and call the “human_attribute_name” with the field name as a parameter on it. By default, “human_attribute_name” will just call “humanize” on your field name (same as our code above) but, when we’re using the Rails I18N support things change a bit.

The first thing that changes is that we can use the I18N support to define labels for those fields (and also for the class names). Let’s take a look at the “config/locale/en.yml” to check out how it looks like:

<pre class="brush:plain">en:
  activerecord:
    models:
      user:
        one: User
        other: Users
    attributes:
      user:
        name: Name
        date_of_birth: Date of birth
        login: Login
        password: Password
        password_confirmation: Confirm Password
        profession: Profession</pre>

Under the “activerecord” namespace we have the “models” and “attributes” namespaces. As you might have guessed, the “models” namespace is used to internationalize your model names and the “attributes” to do the same to your object’s attribute names. While we’re using English as the language things aren’t really that interesting, so we’re going to add Portuguese support:

<pre class="brush:plain">pt-BR:
  activerecord:
    models:
      user:
        one: Usuário
        other: Usuários
    attributes:
      user:
        name: Nome
        date_of_birth: Data de Nascimento
        login: Login
        password: Senha
        password_confirmation: Confirmação da Senha
        profession: Profissão</pre>

And now your form builder will use the Portuguese field names on its labels whenever the current locale is set to “pt-BR” (this isn’t the full file, you can check it out at the project repo). The real catch here is to use the “human_attribute_name” instead of just “humanizing“ the field name.

When human_attribute_name is called it will first try to get the attribute name from your I18N files using the current locale and you don’t really need to be writing a Multilanguage application to use the I18N support, whenever you’re using a language that isn’t pure ASCII only you can use the I18N support and have nice default labels for your form fields. Translating your models using the default “models” and “attributes” namespaces will also internationalize Rails default error messages, as they’re going to use the names of the current locale.

You can see this form builder in action at the <a href="https://github.com/mauricio/sample_social_network/tree">sample_social_network project</a>.
