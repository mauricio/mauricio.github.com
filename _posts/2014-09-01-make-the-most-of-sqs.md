---
layout: post
title: Make the most of Amazon SQS in Ruby for your background worker needs
subtitle: there's a lot more than sending and receiving messages
keywords: aws, amazon, sqs, sns, ruby, aws-sdk, rails
tags:
- useful
- ruby
---

While it's not as popular as other solutions like [Resque](https://github.com/resque/resque), [Sidekiq](http://sidekiq.org/) or [DelayedJob](https://github.com/collectiveidea/delayed_job) at the Ruby community, using [SQS](http://aws.amazon.com/sqs/) to serve a background processing operation is dead simple and offers a lot of guarantees you might not get from the previous options.

The base SQS model is rather simple, you create queues and you push and pull messages from them. The actual advantages come from the fact that you don't have to manage the queuing servers yourself (if you ever had to build an HA Redis cluster for Resque workers you know the pain already) and you can have as many producers and consumers as you would like to, there's no limit on how many messages a queue can hold and how many requests you can make to the SQS servers, so most of the scaling pain you could have setting up a pool of background workers is gone already.

To follow through these examples you have to create an AWS account and setup your AWS keys as environment variables. Check the [Ruby's AWS SDK](https://github.com/aws/aws-sdk-ruby) project for docs on the many ways you can configure your keys.

## Creating queues and sending messages

Creating queues and sending messages is dead simple:

{% highlight ruby %}
sqs = AWS::SQS.new
queue = sqs.queues.create(queue_name, visibility_timeout: 90, maximum_message_size: 262144)
queue.send_message({ file_id: "some-file-id" }.to_json)
{% endhighlight %}

Here we get the `SQS` client, access the queues collection and create a queue. With the queue in hand, we send a message in JSON, but you could use pretty much any text format for your messages, we could be sending YAML messages here and it wouldn't make any difference for the service, only for your code that handles the messaging.

When you create a queue you can also configure it with some options, one is the `maximum_message_size` that defines how many bytes your messages could have. The default value is `64k` but you can go up to `256k` (the value has to be provided in bytes), if your message goes over this limit SQS will reject it with an error so make sure your messages don't go over the limit you have defined.

Another common parameter is the `visibility_timeout` that defines how long a message stays *invisible* to other consumers until it becomes visible again. In SQS we have two types of messages, the *available* and the *in flight* ones. Messages that are available are the ones that can be picked up by consumers polling messages from the queue. Messages that are *in flight* are the ones that have been picked up by one of the consumers but have not been deleted yet. Messages stay *in flight* until the client that picked them up deletes it or the `visibility_timeout` has passed.

When configuring the `visibility_timeout` you should think how long you expect your background workers to take to process the message, the value you set for this field should be considerably longer than the time your workers take to process to make sure this message does not become visible again before your worker can finish processing it. This value is defined in seconds and defaults to 60 seconds.

If the queue is already created, you can pick it up by it's name with:

{% highlight ruby %}
sqs = AWS::SQS.new
queue = sqs.queues.named(queue_name)
queue.send_message({ file_id: "some-file-id" }.to_json)
{% endhighlight %}

If there is no queue by the name you provided, an `AWS::SQS::Errors::NonExistentQueue` error is thrown so make sure you catch this error and create the queue if there isn't an external service creating it for you.

A better way to setup your queues is to use a [cloud formation template to create them]({% post_url 2014-08-16-custom-cloud-formation-resources-in-ruby %}). This way your apps can focus only on pushing and polling messages instead of having to hold knowledge about how your queues are configured.

## Receiving messages from the queue

Building the message receiving part of the process is simple as well, here's an example:

{% highlight ruby %}
sqs = AWS::SQS.new

queue = sqs.queues.named(queue_name)
queue.send_message({ file_id: "some-file-id" }.to_json)

received_message = queue.receive_message(wait_time_seconds: 20)
message = JSON.parse(received_message.body)

## do something with the message

received_message.delete  
{% endhighlight %}

The `receive_message` method returns from 1 to 10 messages (defaults to 1, but the `limit` parameter can be set to any value between 1 to 10 to return more messages). In this case we have also declared the `wait_time_seconds` to be 10, which means the `receive_message` method will wait up to 20 seconds for a message to arrive to return in a long polling style. Setting this parameter is important to avoid busy loops where your code will be constantly making requests to pick messages when there are none to be received, this value can also be configured when creating the queue.

Now that we have the message we can parse it's body (it's just the same JSON we sent before), process and **delete it**. If you forget to **delete** messages they will become visible again and another worker would re-process it and the message would never be removed from the queue.

To avoid having such troubles, you can provide a block to the `receive_message` method that will take care of deleting the message if your block runs successfully so you don't have to care about it. Here's an example:

{% highlight ruby %}
sqs = AWS::SQS.new

queue = sqs.queues.named(queue_name)
queue.send_message({ file_id: "some-file-id" }.to_json)

queue.receive_message(wait_time_seconds: 10) do |received_message|
  message = JSON.parse(received_message.body)
  ## do some processing here
  received_message.delete
end
{% endhighlight %}

And last but not least, you can have a fully functional "forever worker" with just a couple lines of code using the `poll` method:

{% highlight ruby %}
sqs = AWS::SQS.new
queue = sqs.queues.named(queue_name)

queue.poll(wait_time_seconds: 10) do |received_message|
  message = JSON.parse(received_message.body)
  ## do something with the message
  received_message.delete
end  
{% endhighlight %}

This loop will run forever processing messages until the process is killed or an exception is thrown so you might want to also wrap it around a `begin/rescue` block to make sure it continues to run if an error is raised.

## Handling errors

While you'd have to include separate plugins or roll your own solution to retries and failure queues, SQS comes with these concepts baked in with the definition of the `visibility_timeout` value and **redrive policies**.

The workflow is simple, if one of your workers fail to process a message **don't do anything**. Yes, that's it, don't do anything. If you use error monitoring software like [Rollbar](https://rollbar.com/) or [Exceptional](http://www.exceptional.io/), send the actual message text, the message id **and the message `receipt_handle` field** to the service to track the failure. Sending the `receipt_handle` is extremely important here because if you don't store it somewhere it's impossible to delete the message if your system can't handle it or it's causing too many failures.

As you didn't do anything with the message, once it reaches it's `visibility_timeout` it will become visible again and one of your workers will automatically pick it up. You don't have to build fancy retry logic to have this, it just works.

Now, what if a message can't be processed at all?

If you look at the [ReceivedMessage](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SQS/ReceivedMessage.html) documentation you'll see there's a field called `approximate_receive_count`, we could include at our workers logic that checks the value of this field and if it has been received more than X times we delete the message and move it to a separate failure queue, right?

Wrong!

Half wrong, I mean. That's exactly what we're going to do but we won't write any code for it since it's already part of SQS, this feature is called **redrive policy**. At any SQS queue you can declare a redrive policy that takes a receive count and a destination queue, in messaging lingo these destination queues are often called *dead letter queues* because they receive the messages no one could handle/process, once the message has been received X times, SQS will automatically move it to the dead letter queue and you can run diagnostics and do whatever you would like to with these dead messages.

While you can declare redrive policies for your queues right from the SQS console UI or the command line, ignore both of those options and [declare your queues in a cloud formation template]({% post_url 2014-08-16-custom-cloud-formation-resources-in-ruby %}). You'll thank me latter.

Here's a condensed example of how declaring a queue with a redrive policy looks like:

{% highlight javascript %}
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "Creates the queues with a redrive policy",
    "Mappings": {},

    "Resources": {
        "TranscoderDeadQueue": {
            "Type": "AWS::SQS::Queue",
            "Properties": {
                "ReceiveMessageWaitTimeSeconds": 20,
                "VisibilityTimeout": 600,
                "QueueName": "transcoder_dead-production"
            }
        },
        "TranscoderQueue": {
            "Type": "AWS::SQS::Queue",
            "Properties": {
                "ReceiveMessageWaitTimeSeconds": 20,
                "VisibilityTimeout": 600,
                "QueueName": "transcoder-production",
                "RedrivePolicy": {
                    "maxReceiveCount": 10,
                    "deadLetterTargetArn": {
                        "Fn::GetAtt": [ "TranscoderDeadQueue", "Arn" ]
                    }
                }
            }
        }
    }
}
{% endhighlight %}

At this example, if a message at the `transcoder-production` queue is received 10 times, it is then sent to the `transcoder_dead-queue` and won't be processed by the workers that are polling messages from the `transcoder-queue` anymore.

And now you have most of the error handling stuff you'd have to care about already done for you.

## Declaring custom message attributes

When you want to send metadata about the message, you don't have to pollute the message itself, you can declare custom attributes when sending the message and receivers can pick up this metadata without having to look at the message itself.

If we wanted to let consumers know the format of the text that is at the message, we could include a `content_type` attribute to messages and consumers could read that and select the right parser for the format. Let's look at an example of that:

{% highlight ruby %}
sqs = AWS::SQS.new

queue = sqs.queues.named(queue_name)
queue.send_message(
  { file_id: "some-file-id" }.to_json,
  message_attributes: {
    "content_type" => {
      "string_value" => "application/json",
      "data_type" => "String",
    }
  }
)

received_message = queue.receive_message(wait_time_seconds: 10, message_attribute_names: ['content_type'])  

message = case received_message.message_attributes["content_type"][:string_value]
when 'application/json'
  JSON.parse(message.body)
else
  raise "Invalid message format #{received_message.message_attributes["content_type"][:string_value]}"
end
{% endhighlight %}

The main advantage of using message attributes instead of including these fields at the message itself is that you don't have to parse the message to be able read the attribute values so you can include information about how the message should be parsed. You could, for instance, include a field that declares if the payload is compressed or not and then decide to unpack the message, all without having to look at the message body at all.

When declaring attributes, you have to define the `data_type`, which can be `String`, `Number` or `Binary`. You can include an extra tag to one of these types as in `Number.Dollars` or `Binary.Png` so you can differentiate the various different numbers you have. The value field name has to match the type you used, if the type is string, the field is `string_value`, `number_value` for numbers and `binary_value` for a binary field. The attribute name is the key you declare for the hash.

To read the value, you have to ask SQS to include the attribute as well, otherwise your message won't have any metadata. So, when calling the `receive_message` method include the `message_attribute_names` option with an array of the metadata fields you expect to find.

The hash returned is in the following format:

{% highlight ruby %}
{ "content_type" => {
    :string_list_values => [],
    :binary_list_values => [],
    :data_type => "String",
    :string_value => "application/json"}
}
{% endhighlight %}

## Careful with your `visibility_timeout`

Not that long ago I had a probem where the same message would become visible long before the worker was finished processing it. This made the same message become visible many times from many different workers and, as you might imagine, led to a lot of rework at our servers.

When deciding what should be your `visibility_timeout` **be pessimistic** and make sure this same timeout is reflected at your workers. Maybe right now you can't see how that incredibly simple worker could take more than 1 minute to process the message but network delays, slow machines, too much disk IO and other problems could easily make your worker take much longer to actually perform the operation and delete the message, making it become available for other workers to pick up.

A simple solution for this (if you're in Ruby 1.9 or newer) is to use the [Timeout](http://ruby-doc.org/stdlib-1.9.3/libdoc/timeout/rdoc/Timeout.html) functionality to make sure your code gives up processing before it reaches the time limit. Still, the timeout **should be lower** than the `visibility_timeout` you defined for your queue.

## Use batch processing whenever possible

We spoke about the `send_message` and `receive_messsage` methods but both of them have their own batch processing versions where you can send at most 10 messages and receive 10 messages. Whenever possible, you should group your messages in groups of 10 to send them in a batch using the `batch_send` method.

And when it makes sense, you should do the same for the `receive_message` method as well (that is also aliased to `receive_messages`) declaring the `limit` option to `10` to receive 10 messages in a row.

Whenever your worker can do his operations in batches (like indexing stuff in an full text search server) you should make use of this to cram as many updates as possible in a single request instead of forcing yourself to handle only one message at a time. A lot of servers and applications are optimized to perform operations in bulk, so you should make use of this feature to do more work using less resources.

And don't forget to call `batch_delete` to delete all messages you have received as well, you don't want them becoming visible for all the other clients, do you?

## Fan out messages mixing SNS and SQS

Whenever you have to send the same message to many different queues, you don't want to use `SQS` directly, you want to use an [SNS](http://aws.amazon.com/sns/) topic that distributes it's messages to many `SQS` queues. Here's an example:

{% highlight ruby %}
sns = AWS::SNS.new
sqs = AWS::SQS.new

topic = sns.topics.create(topic_name)
queue = sqs.queues.create(queue_name, visibility_timeout: 90)

subscription = topic.subscribe(queue)
subscription.raw_message_delivery = true

sample_message = "this is a sample message"

topic.publish(sample_message)

received_message = queue.receive_message(wait_time_seconds: 10)  
{% endhighlight %}

And you could have many other `SQS` queues subscribed to this `SNS` topic and receiving messages from it. Imagine you're building a service that publishes updates to many webhooks (like GitHub!), instead of manually sending a message to each queue of each service, the services would subscribe their queues to a central `SNS` topic and you would only push the notifications to the `SNS` topic, the topic would take care of distributing the message to everyone that is subscribed for you.

## Always cache the `AWS::SQS::Queue` object

A common mistake when building apps with `SQS` is calling `sqs.queues.named(queue_name)` all around instead of caching the returned object. Calling the method `named(queue_name)` causes you to make a request to `SQS` to get the queue URL to where requests are sent and build the SQS object.

Whenever possible configure the full queue URL at a config file in your app and use it to build the `queue` object to avoid making this unnecessary HTTP request whenever you need to push and pull messages to the queue, it's dead simple to do it:

{% highlight ruby %}
queue_url = "https://sqs.us-east-1.amazonaws.com/12345678/transcoder-production"
sqs = AWS::SQS.new
queue = sqs.queues[queue_url] # does not make an HTTP request
{% endhighlight %}

And now we have the `queue` object ready to send and receive messages without having to ask `SQS` for the queue URL.

## Give it a try

SQS provides a lot of features and greatly simplifies working with background queues by removing all the queue management from your app. It's definitely a great option if you have a lot of queues and background processing and don't want to be responsible for managing all the databases and redis instances required to use the other tools.
