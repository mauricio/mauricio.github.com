---
layout: post
title: Going down the rabbit hole of Ruby's object conversions
subtitle: less magic is good from time to time
keywords: ruby, rspec, coercion, conversion, bugs, github
tags:
- ruby
- useful
---

This new year I decided I'd do a bit less of community work by [answering stuff at
SO](http://stackoverflow.com/users/293686/mauricio-linhares) and mailing lists and
would contribute more actual code to OSS projects. So, from time to time I wander
about projects I use, and try to contribute by fixing stuff and sending PRs.

This has actually led me [tqo figure out some interesting stuff]({% post_url 2014-02-01-never-match-against-ruby-default-execeptions-at-your-tests %}) and a [new bugfix I did for rspec-mocks](https://github.com/rspec/rspec-mocks/pull/577) a couple days ago sent me down the rabbit hole of Ruby's object conversions.

## The Bug

The actual bug was found indirectly by [@adamstegman](https://github.com/adamstegman). He was using test doubles in `raise` statements and they were causing a `RuntimeError` to be raised instead of the class he was using as a double, so his specs weren't matching the expected error. In Ruby, you can raise objects of type `Exception`, strings or objects that act like strings.

These two last cases are the interesting ones here, string or string like objects.

So, what is a string like object?

In Ruby, a string like object is any object that has a `to_str` method defined on it. So, methods that expect to take a string, will usually check if there is a `to_str` method defined there if the object isn't a string.

For `rspec` doubles, having the `to_str` method defined made them coercible to string (an unintended side effect, most likely) and raised it's string representation.

If you try to raise something that isn't an `Exception`, string or string like, that's what you get:

{% highlight ruby %}
2.1.0 :001 > class Something; end
 => nil
2.1.0 :002 > raise Something.new
TypeError: exception class/object expected
	from (irb):2:in `raise'
	from (irb):2
{% endhighlight %}

Given the double shouldn't really be responding to stuff the user didn't actually say it should respond to, making it coercible to string could hide weird bugs inside the code, since somewhere along the way the code could convert it to a string and the double itself would be gone.

After figuring out what was going on, the fix was simple, remove the `to_str` method from `TestDouble` and now you would see the error above when trying to raise a double, as expected.

And it's this subtle bug that takes us to the real subject for this blog post, Ruby's object conversions.

## Explicit conversions

No, that's not what you're thinking.

Explicit conversions are when objects define methods like `to_s`, `to_i`, `to_f`, `to_a` and `to_h`. This means you can call these methods on the objects and they will return a string, an int, a float, an array or a hash, respectively, that represents the object.

These are explicit because the Ruby runtime will not call these methods for you to transform one object into another. The most common example is:

{% highlight ruby %}
2.1.0 :001 > 1 + "40"
TypeError: String can't be coerced into Fixnum
	from (irb):1:in `+'
	from (irb):1
{% endhighlight %}

Well, that doesn't work, but this works:

{% highlight ruby %}
2.1.0 :001 > 1 + "40".to_i
 => 41
{% endhighlight %}

While `String` does define a `to_i` method, Ruby won't call it for me, I have to manually call the method here to make sure the `String` object is transformed to an `int` before summing them.

__oh, but that is tedious, isn't it?__ you might think. Well, not if you fall for a bug that's caused by the runtime coercing your objects into something else, just like the bug that was fixed above. Personally, I'd take a well known behavior over magic all the time.

If you have programmed in languages like Java or C#, this might be awkward. In both languages, a String somewhere in a `+` expression will infect the sum and make it all string concatenation. This leads to subtle bugs and unexpected behavior, you can even see a lengthy discussion at the [scala-users](https://groups.google.com/forum/#!msg/scala-user/Mbtp_Cq6zKI/XZAdRftpdw8J) about the nightmare it is to have everything magically being turned into strings. Thanks, Matz, you did great!

Now back to explicit conversions, the only special case here is when your object is inside a string interpolation expression. Look at this:

{% highlight ruby %}
2.1.0 :001 > "me" + 10
TypeError: no implicit conversion of Fixnum into String
	from (irb):1:in `+'
	from (irb):1
{% endhighlight %}

Doesn't work, `Fixnum` can't be implicitly converted into `String`. But if we do this:

{% highlight ruby %}
2.1.0 :001 > "me #{10}"
 => "me 10"
{% endhighlight %}

Perfect! That's what we're looking for. In the specific case of string interpolation, Ruby __will__ call the object's `to_s` method and use that as the output to be included in the string. That's the only case you will see the runtime automatically calling one of the explicit conversion methods.

So, if the object you're working with implements one of these methods and you need to transform it, just call them. For instance, if you have an array of pairs:

{% highlight ruby %}
2.1.0 :001 > [ ["me",10], ["you", 20] ].to_h
 => {"me"=>10, "you"=>20}
{% endhighlight %}

You can easily turn it into a `Hash` calling `to_h` on it, as you can turn a `Range` into an `Array` by calling `to_a` on it:

{% highlight ruby %}
2.1.0 :001 > ('a'..'f').to_a
 => ["a", "b", "c", "d", "e", "f"]
{% endhighlight %}

## Implicit conversions

Now this is where the magic really starts to show itself. Ruby defines some implicit conversion methods that are called under specific circunstances on objects to check if they can be transformed to something else, they are `to_int`, `to_str`, `to_ary`, `to_hash` and `to_enum` (you'll see some others below).

There isn't an actual list of where or when these methods are called. Given we don't annotate variables or methods with types in Ruby (as we do in languages like Java, for instance) the runtime can't figure out when this would be necessary and the built in funcionality just tries do to this when it thinks it's necessary. One of the examples of this is exacly the `rspec` bug above.

Let's look at the C code that gets called when you try to raise an exception, it starts on `rb_f_raise` (or `Kernel.raise`):

{% highlight c %}
static VALUE
rb_f_raise(int argc, VALUE *argv)
{
    VALUE err;
    VALUE opts[raise_max_opt], *const cause = &opts[raise_opt_cause];

    argc = extract_raise_opts(argc, argv, opts);
    if (argc == 0) {
	if (*cause != Qundef) {
	    rb_raise(rb_eArgError, "only cause is given with no arguments");
	}
	err = get_errinfo();
	if (!NIL_P(err)) {
	    argc = 1;
	    argv = &err;
	}
    }
    rb_raise_jump(rb_make_exception(argc, argv), *cause);

    UNREACHABLE;
}
{% endhighlight %}

The important piece here is `rb_make_exception` which, calls `make_exception` below:

{% highlight c %}
static VALUE
make_exception(int argc, VALUE *argv, int isstr)
{
    VALUE mesg, exc;
    ID exception;
    int n;

    mesg = Qnil;
    switch (argc) {
      case 0:
	break;
      case 1:
	exc = argv[0];
	if (NIL_P(exc))
	    break;
	if (isstr) {
	    mesg = rb_check_string_type(exc);
	    if (!NIL_P(mesg)) {
		mesg = rb_exc_new3(rb_eRuntimeError, mesg);
		break;
	    }
	}
	n = 0;
	goto exception_call;

      case 2:
      case 3:
	exc = argv[0];
	n = 1;
      exception_call:
	if (exc == sysstack_error) return exc;
	CONST_ID(exception, "exception");
	mesg = rb_check_funcall(exc, exception, n, argv+1);
	if (mesg == Qundef) {
	    rb_raise(rb_eTypeError, "exception class/object expected");
	}
	break;
      default:
	rb_check_arity(argc, 0, 3);
	break;
    }
    if (argc > 0) {
	if (!rb_obj_is_kind_of(mesg, rb_eException))
	    rb_raise(rb_eTypeError, "exception object expected");
	if (argc > 2)
	    set_backtrace(mesg, argv[2]);
    }

    return mesg;
}
{% endhighlight %}

The piece we're looking for here is the call to `rb_check_string_type`, which is the function that converts something that has a `to_str` method into a real `String`, let's see how it's implemented:

{% highlight c %}
VALUE
rb_check_string_type(VALUE str)
{
    str = rb_check_convert_type(str, T_STRING, "String", "to_str");
    return str;
}
{% endhighlight %}

And finally, let's look at `rb_check_convert_type`:

{% highlight c %}
static struct conv_method_tbl {
    const char *method;
    ID id;
} conv_method_names[] = {
    {"to_int", 0},
    {"to_ary", 0},
    {"to_str", 0},
    {"to_sym", 0},
    {"to_hash", 0},
    {"to_proc", 0},
    {"to_io", 0},
    {"to_a", 0},
    {"to_s", 0},
    {NULL, 0}
};

static VALUE
convert_type(VALUE val, const char *tname, const char *method, int raise)
{
    ID m = 0;
    int i;
    VALUE r;

    for (i=0; conv_method_names[i].method; i++) {
	if (conv_method_names[i].method[0] == method[0] &&
	    strcmp(conv_method_names[i].method, method) == 0) {
	    m = conv_method_names[i].id;
	    break;
	}
    }
    if (!m) m = rb_intern(method);
    r = rb_check_funcall(val, m, 0, 0);
    if (r == Qundef) {
	if (raise) {
	    rb_raise(rb_eTypeError, "can't convert %s into %s",
		     NIL_P(val) ? "nil" :
		     val == Qtrue ? "true" :
		     val == Qfalse ? "false" :
		     rb_obj_classname(val),
		     tname);
	}
	return Qnil;
    }
    return r;
}

VALUE
rb_check_convert_type(VALUE val, int type, const char *tname, const char *method)
{
    VALUE v;

    /* always convert T_DATA */
    if (TYPE(val) == type && type != T_DATA) return val;
    v = convert_type(val, tname, method, FALSE);
    if (NIL_P(v)) return Qnil;
    if (TYPE(v) != type) {
	const char *cname = rb_obj_classname(val);
	rb_raise(rb_eTypeError, "can't convert %s to %s (%s#%s gives %s)",
		 cname, tname, cname, method, rb_obj_classname(v));
    }
    return v;
}
{% endhighlight %}

The code is rather simple, first, it checks if the type already is the type we want to convert to. If it is, return it. Otherwise call `convert_type` with the value, type and conversion method.

`convert_type`, in turn, will check if the object implements the conversion method. In our case, it would check if the object implements `to_str`. Also, it only does the conversion if the method is in the list above, if it isn't one of those methods it would just ignore it and not perform any conversion.

If we wanted to implement this in pure Ruby, it could be something like:

{% highlight ruby %}
METHODS = ["to_int", "to_ary","to_str","to_sym","to_hash", "to_proc", "to_io","to_a", "to_s"]
def convert_type( value, type, method, raise_on_error = false )
  result = if value.kind_of?(type) || value.nil?
    value
  elsif METHODS.include?(method) && value.respond_to?(method)
  	value.send(method)
  else
    nil
  end

  if raise_on_error && !result.nil? && result.kind_of?(type)
  	raise TypeError, "can't convert #{value.class.name} to #{type.name} (#{value.class.name}##{method} gives #{result.class.name})"
  end

  result
end
{% endhighlight %}

So, while we call these methods __implicit converters__, they're not that implicit. The runtime has to manually decide when this is required and call `rb_check_string_type` to convert what you have into a string or into any of the other types by itself. So, unless the documentation is specific about this or you know the code will make this check, don't expect your objects to be converted into something else.

Another common built-in conversion is when you're comparing `String`, `Array` and `Hash` objects with `==`. The current implementation will check if the right-hand object is of the same type of the left-hand one and if it isn't, it will try to convert it. Here's the `Hash#==` implementation:

{% highlight c %}
static VALUE
hash_equal(VALUE hash1, VALUE hash2, int eql)
{
    struct equal_data data;

    if (hash1 == hash2) return Qtrue;
    if (TYPE(hash2) != T_HASH) {
	if (!rb_respond_to(hash2, rb_intern("to_hash"))) {
	    return Qfalse;
	}
	if (eql)
	    return rb_eql(hash2, hash1);
	else
	    return rb_equal(hash2, hash1);
    }
    if (RHASH_SIZE(hash1) != RHASH_SIZE(hash2))
	return Qfalse;
    if (!RHASH(hash1)->ntbl || !RHASH(hash2)->ntbl)
        return Qtrue;
    if (RHASH(hash1)->ntbl->type != RHASH(hash2)->ntbl->type)
	return Qfalse;

    data.tbl = RHASH(hash2)->ntbl;
    data.eql = eql;
    return rb_exec_recursive_paired(recursive_eql, hash1, hash2, (VALUE)&data);
}
{% endhighlight %}

As you can see, if the object isn't a `Hash`, it goes to `rb_respond_to(hash2, rb_intern("to_hash"))` to check if the object can be converted to a hash, if it can't, it just returns false right away since you can't compare some generic object with a hash.

## Arithmethic coercion

One little known feature of Ruby numbers is the `coerce` method, it allows you to mix different types of numbers to do your math correctly. Let's look at what I would have to do to sum the `1/5` to `10`:

{% highlight ruby %}
2.1.0 :001 > require 'rational'
 => true
2.1.0 :002 > r = Rational(1,5)
 => (1/5)
2.1.0 :003 > result = r.coerce(10)
 => [(10/1), (1/5)]
2.1.0 :004 > sum = result.inject(Rational(0,1), :+)
 => (51/5)
{% endhighlight %}

As you can see, I start with the `Rational` object and then call `coerce` on it with the integer. As a result of that, the `10` integer is transformed into the `10/1` rational (that is just `10`) and we can then sum both of them. I could just manually sum them, but since they are inside an array already it's much simpler just to use `inject` to perform the sum.

## Boolean coercion

Operators and control structures that expect booleans in Ruby will take any kind of object and use it. There are two cases, `false` and `nil` are __falsy__ so they will behave as if it was a real `false` boolean value (ie. `if nil` will go to the `else` piece), and the other case is __everything else is truthy__.

Empty strings, arrays, hashes, `0`, they will all be assumed to be `true` values. Every single object that is not `false` or `nil` is assumed to be true when used in control structures and boolean operators, doesn't matter what the object is.

This leads to some interesting developments when using boolean operators in Ruby, for instance:

{% highlight ruby %}
2.1.0 :001 > false || nil
 => nil
{% endhighlight %}

Boolean operators in Ruby will not return a boolean, but the last expression that was evaluated by the operator and this is both good a bad. Good, because it lets you write terse statements like the elvis operator:

{% highlight ruby %}
2.1.0 :003 > me ||= 10
 => 10
{% endhighlight %}

This is equivalent to `me = me || 10`.

And bad because if you actually need something to always be a boolean (maybe you are turning this value to JSON or something else) you need to add a bit more code:

{% highlight ruby %}
2.1.0 :005 > !!(10 && [])
 => true
{% endhighlight %}

Without this, the result of executing that `&&` operation would be `[]` (the empty array).

## Don't trust magic

The main takeaway I had from all this is that you don't need magic. Think once, twice, three, four, ten times before you implement one of those implicit conversion methods in your objects, because you never know when it will be called and how this could change the behavior of your system.

If you're not 100% sure you actually need it, just don't use it. Stick to the explicit conversion methods, where you know what's going on and what is going to happen instead of letting your code fly away and your objects be magically transformed into something else.
