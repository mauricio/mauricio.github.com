---
layout: post
title: Never match against Ruby's default exceptions at your tests
---

While working in an app using Rails 4 and RSpec's beta version, I came across a weird bug that caused the following backtrace:

    Failure/Error: expect {
      expected RSpec::Mocks::VerifyingDoubleNotDefinedError, got #<NoMethodError: undefined method `name' for #<RSpec::Mocks::NamedObjectReference:0x000001026308a0>> with backtrace:
      # ./lib/rspec/mocks/example_methods.rb:182:in `declare_verifying_double'
      # ./lib/rspec/mocks/example_methods.rb:46:in `instance_double'
      
Going right where the error happened I saw this:

{% highlight ruby %}
def self.declare_verifying_double(type, ref, *args)
  if RSpec::Mocks.configuration.verify_doubled_constant_names? &&
    !ref.defined?

    raise NameError,
      "#{ref.name} is not a defined constant. " +
      "Perhaps you misspelt it? " +
      "Disable check with verify_doubled_constant_names configuration option."
  end

  declare_double(type, ref, *args)
end
{% endhighlight %}	

So, pretty obvious, isn't it?

It's trying to call a `name` method at the double/mock ref since it isn't defined yet, but the `double` doesn't have a method called `name` (the correct method would be `description`). 

Now, before going on to fix the issue, we need to write a spec that shows it happening in a controlled environment. I move on to the specs for this specific file and find this: 

{% highlight ruby %}
describe 'when verify_doubled_constant_names config option is set' do
  it 'prevents creation of instance doubles for unloaded constants' do
    expect {
      instance_double('LoadedClas')
    }.to raise_error(NameError)
  end

  it 'prevents creation of class doubles for unloaded constants' do
    expect {
      class_double('LoadedClas')
    }.to raise_error(NameError)
  end
end
{% endhighlight %}
	
Hey, **there is** a spec for this behaviour. Why isn't this spec failing?

Well, that's the catch, `NameError` is the superclass for `NoMethodError` so the match is, in a way, correct. It definitely raises a `NameError` but not the `NameError` we expected it would raise.

In this case, there are many possible solutions, we could match on the exception message, to make sure it definitely generates the exception we would want it to or we can create our own error to symbolise this specific error (and that's what I did when [I sent them a PR to fix it](https://github.com/rspec/rspec-mocks/pull/550/files)).

When you use a custom error to signal that something has gone wrong, it's much less likely that you will get a false positive like this one. You know only your own code would manually raise that error (given all the other code doesn't even know it exists) so you would be pretty much safe from falling for a case like this one.

So, avoid using and matching against Ruby's default exceptions, when you need to raise something, create your own exception classes, it's absurdly simple:

{% highlight ruby %}
VerifyingDoubleNotDefinedError = Class.new(StandardError)
{% endhighlight %}
     
And you end up with better documentation, better tests and prevent unexpected errors like this one. Also, always be as specific as possible, if you have different errors that represent different states for your application, make sure your exceptions reflect that as well. Having a single `MyAppError` class is hardly any better than raising `Exception` and `StandardError` all around.