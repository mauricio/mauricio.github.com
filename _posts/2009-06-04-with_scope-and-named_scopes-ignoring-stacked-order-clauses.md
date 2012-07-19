---
layout: post
title: with_scope and named_scopes ignoring stacked :order clauses
tags:
- en_US
- ruby
- ruby on rails
status: publish
type: post
published: true
meta:
  _su_keywords: ''
  _edit_last: '1'
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1281788473";}";
  delicious: s:78:"a:3:{s:5:"count";s:1:"3";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1280621455";}";
  dsq_thread_id: '218407830'
  _su_description: ''
---
If you've been using with_scope and named_scopes a lot with ActiveRecord you have probably noticed that the :order clauses defined at the scopes are lost and only the first :order clause is used. If you defined an :order clause you'd like to have it merged with the other ones already provided. Here's a simple example:

<pre class="brush:ruby">class User
  named_scope :by_first_name, :order => "#{quoted_table_name}.first_name ASC"
  named_scope :by_last_name, :order => "#{quoted_table_name}.last_name ASC"
end</pre>

Our user has two named scopes defined and both of them define an :order clause, if we try to run a finder like this:

<pre class="brush:ruby">User.by_first_name.by_last_name.all</pre>

This is the generated query:

<pre class="brush:sql">SELECT * FROM `users` ORDER BY `users`.first_name ASC</pre>

As you've noticed, only the first :order clause was used, the last one was lost. Our ideal SQL query would have to look like this, with both :order clauses being used:

<pre class="brush:sql">SELECT * FROM `users` ORDER BY `users`.last_name ASC , `users`.first_name ASC</pre>

That's why we're going to hack the with_scope method a litle bit to reach our goal. This issue <a href="https://rails.lighthouseapp.com/projects/8994/tickets/2253-named_scope-and-nested-order-clauses">was already reported to the Rails issue tracker</a> but there's no fix yet so our only hope is to monkeypatch Rails to behave as we expect it to, so here's a really simple fix for the problem:

<pre class="brush:ruby">ActiveRecord::Base.class_eval do

  class << self

    def merge_orders( *orders )
      orders.map! do |o|
        if o.blank?
          nil
        else
          o.strip!
          o
        end
      end
      orders.compact!
      orders.join( ' , ' )
    end

    def with_scope_with_hack(method_scoping = {}, action = :merge, &block)
      method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

      # Dup first and second level of hash (method and params).
      method_scoping = method_scoping.inject({}) do |hash, (method, params)|
        hash[method] = (params == true) ? params : params.dup
        hash
      end

      method_scoping.assert_valid_keys([ :find, :create ])

      if f = method_scoping[:find]
        f.assert_valid_keys(VALID_FIND_OPTIONS)
        set_readonly_option! f
      end

      # Merge scopings
      if [:merge, :reverse_merge].include?(action) && current_scoped_methods
        method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
          case hash[method]
          when Hash
            if method == :find
              (hash[method].keys + params.keys).uniq.each do |key|
                merge = hash[method][key] && params[key] # merge if both scopes have the same key
                if key == :conditions && merge
                  if params[key].is_a?(Hash) && hash[method][key].is_a?(Hash)
                    hash[method][key] = merge_conditions(hash[method][key].deep_merge(params[key]))
                  else
                    hash[method][key] = merge_conditions(params[key], hash[method][key])
                  end
                elsif key == :include && merge
                  hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                elsif key == :joins && merge
                  hash[method][key] = merge_joins(params[key], hash[method][key])
                elsif key == :order && merge
                  hash[method][key] = merge_orders(params[key], hash[method][key])
                else
                  hash[method][key] = hash[method][key] || params[key]
                end
              end
            else
              if action == :reverse_merge
                hash[method] = hash[method].merge(params)
              else
                hash[method] = params.merge(hash[method])
              end
            end
          else
            hash[method] = params
          end
          hash
        end
      end

      self.scoped_methods << method_scoping
      begin
        yield
      ensure
        self.scoped_methods.pop
      end
    end

    alias_method_chain :with_scope, :hack

  end

end</pre>

You can place this code at an initializer (maybe called with_scope_fix.rb) or at your lib folder and require it in your initializers. And now all your :order clauses defined by named_scope or with_scope calls will be correctly merged and will not be lost in your code.
