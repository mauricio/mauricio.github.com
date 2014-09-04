---
layout: post
title: Use your MongoDB `_id` field as your created at timestamp
subtitle: and you can get away without creating an index for the created_at field
keywords: ruby, mongodb, timestamps, time, date, index
tags:
- useful
- ruby
---

From time to time I have to run queries against our MongoDB collections picking documents created over specific time ranges but not all of those collections have an index at the `created_at` field. This led to some of them taking too long to run even on our secondaries or the hidden replica.

This changed when I was presented to the fact that the `ObjectId` values produced by Mongo already include a timestamp on them!

I could just use the collection `_id` field to do date range queries and since the field is indexed by default I didn't even have to care about indexing it myself.

If you're using [Mongoid](http://mongoid.org/), a simple way of creating these values is using the `Moped::BSON::ObjectId.from_time` method. Let's look at an example that finds all items created today:

{% highlight ruby %}
today_object_id = Moped::BSON::ObjectId.from_time(Time.now.utc.at_beginning_of_day) # 5407ab800000000000000000 for "2014-09-04 00:00:00 UTC"
items_created_today = MongoidModel.where(:_id.gte => today_object_id)
{% endhighlight %}

This finds all items that were created after the date you provided (`at_beginning_of_day` is a method that's included by `ActiveSupport` at `Time` objects) and it should be really quick due to the index at `_id` that's already there all the time.

If you have to go through a lot of data and don't want to keep cursors alive at the server (avoid long running cursors on MongoDB) you can use this same method to build a manual cursor that loads all items for every day for 30 days and does stuff to them. Here's how it would look like:

{% highlight ruby %}
last_30_days = 29.times.inject([30.days.ago.utc.at_beginning_of_day]) do |acc,_|
  acc << acc.last.advance(days: 1)
  acc
end

last_30_days.each do |day|
  start_object_id = Moped::BSON::ObjectId.from_time(day)
  end_object_id = Moped::BSON::ObjectId.from_time(day.advance(days: 1))  
  items = MongoidModel.where(:_id.gte => start_object_id).where(:_id.lt => end_object_id)
  # do something with the items here
end
{% endhighlight %}

Here we find any items that were created at that day until the beginning of the next one. You can build any kind of date range query against `ObjectId` fields just by making use of the `from_time` method, if you can create a `Time` object, you can produce an `ObjectId` value to use it as a filter.

This also works if you're using the main MongoDB driver, just use the [BSON::ObjectId.from_time](http://api.mongodb.org/ruby/current/BSON/ObjectId.html#from_time-class_method) method that works exactly the same way. Give it a `Time` object and it will give you the `ObjectId` value that represents that timestamp.

And if you'd like to get an `ObjectId` without writing any Ruby code at all, use [Steve Ridout's ObjectId generator](http://steveridout.github.io/mongo-object-time/) and you should be good to go.

Now stop indexing your `created_at` field :)
