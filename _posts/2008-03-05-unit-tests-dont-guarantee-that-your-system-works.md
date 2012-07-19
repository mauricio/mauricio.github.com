---
layout: post
title: Unit tests don’t guarantee that your system works
tags:
- bdd
- en_US
- quality
- rspec
- ruby
- ruby on rails
- tdd
- testing
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  delicious: s:78:"a:3:{s:5:"count";s:1:"1";s:9:"post_tags";s:0:"";s:4:"time";s:10:"1280358961";}";
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1281209939";}";
  dsq_thread_id: '217521012'
  _su_keywords: ''
  _su_description: ''
  _efficient_related_posts: a:1:{i:0;a:4:{s:2:"ID";s:3:"228";s:10:"post_title";s:27:"Como
    tratar os seus testes?";s:7:"matches";s:1:"2";s:9:"permalink";s:53:"http://techbot.me/2008/01/como-tratar-os-seus-testes/";}}
  _relation_threshold: '2'
---
Last week we had <a href="http://rubyforge.org/pipermail/rspec-users/2008-February/006012.html">an interesting message at the RSpec users list</a>, the most interesting part of it is the following:

<blockquote>“I also had to go into specs on a project I'm not working on, and found an unholy hive of database-accessing specs. It's disheartening. Basically, it's cargo cult development practices - using the "bestpractice" without actually understanding it.”</blockquote>
You might have read this before, <em>“/specs|tests/ that access the database are evil”</em>, but have you ever asked yourself why?

Behavior Driven Development is the next step after Test Driven Development and it borrows many best practices found in the later. The two principles that interest us most in this conversation is test-first development and unit testing.

The idea behind test-first development is that before writing your code, you should write a test stating what you want you “future” code to do. By writing the test before the code you get to work on the public interface provided by your object, the test is the first client of your code, so, if your public interface is cumbersome or difficult to use, this test will be able to catch a bad idea before it’s materialized in your code.

And where is unit testing in all this? You should be doing test-first using unit tests, as unit tests will guarantee that the code you wrote for that single unit (a method, probably) works alone. If you have more objects that need to be used to test this specific behavior, you should use mock objects (fake objects) in their places, so you won’t be testing them in your unit test. Remember, unit tests should only test a unit of code, no more than that. We should do it this way so we don't get distracted with the other objects implementation, we focus in testing our target, not it's dependencies.

When we’re writing specs for our objects they should usually work as unit tests, they should only assert the behaviors of a single unit of code, everything else should be done using mocks and stubs. But I said <strong>usually</strong>.

As I said before, unit tests and your common specs, should only assert the behaviors of a unit of code without considering their relationships with the other objects on the system, but this only guarantees that they work as units. This will never guarantee that they will really work when in real contact with the other objects in the system, <strong>unit testing don’t guarantee that your system works</strong>, they surely help you to reach this goal, but they aren't enough.

And what it has to do with that message, anyway?

That spec that access the database is just like an integration test, it asserts that the code being tested works fine when integrated with the database. So, the integration tests are the ones that really show you that your code works as a system, not only as a group of lonely objects.

I'm not saying that you should leave the unit tests behind, because they have a big importance to help you design your code and be sure that it works as a unit, but you shouldn’t rely only in them to test your system, a good suite of integration tests will give you the trust that everything works fine in conjunction.

And sometimes you can't unit test a functionality, it's all about integration. Let's take the “<strong>validates_uniqueness_of</strong>” validation in <strong>ActiveRecord</strong> as an example, if you're writing a spec for your <strong>ActiveRecord</strong> model, you should add one 'it' statement showing that this is needed (you're specifying how your model behaves, remember?), so here's how it could look:

<pre class="brush:ruby">it 'Should not be valid if there is another one with the same name' do
           @common_name = 'testuser'
           @user = User.create( :name => @common_name )
           @another_user = User.new( :name => @common_name )
           @another_user.should have(1).error_on(:name)
end</pre>

How could you perform this spec without touching the database?

First, you could look ad the “validates_uniqueness_of” source code, figure out how it works and stub it to return what you want, but this is bad because if the framework code changes your specs would break. The other way would be changing the database adapter to a mocked one and send exactly the result you wanted, but this is basically overkill. So why don't you just leave the “purism” behind, test it in your database and be happy that your code works fine?

One important thing to notice is that integration tests are also slower to run, so you wouldn't like to wait for the full suit run before performing a commit, usually you would run the unit and integration tests that are most likely to break if you did something wrong, the ones related to what you're doing now and just be done with it.

So, if you're in a project that has database accessing specs or specs that are using many real objects (and not mocks), don't feel bad, but be sure that who wrote it knows that he is doing and that everything that can be unit tested is being unit tested. Integration tests should be written after your functionality is implemented and tested with unit tests, they are not interchangeable, nor you will replace one with the other.

And be sure to never commit your code before running your tests :)

PS: Originally published <a href="http://blog.codevader.com/2008/03/05/unit-tests-dont-guarantee-that-your-system-works/">at the CodeVader blog</a>
