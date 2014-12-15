---
layout: post
title: Upload directly to S3 using Rails and the new S3 notifications
subtitle: with a pinch of SQS and CloudFormations
keywords: ruby, aws, amazon, sqs, sns, s3, cloudformation
- useful
---

One of the best things about S3 is that you don't have to build a huge infrastructure to receive the file uploads from your users, you can just direct them to a pre-signed URL and they would upload their files there. The downside of this process was that you had to include a last step just after the upload where the user would have to notify your app that the upload was completed.

Now this complication has finally been lifted with the new [S3 notifications](http://aws.amazon.com/blogs/aws/s3-event-notification/) announced by Amazon. You can now subscribe your S3 bucket to an SNS topic and receive notifications of files uploaded directly from Amazon, avoiding error states were the user finishes uploading the file but can't notify you back because he's having network issues or your app is failing.

In this example, we will build a simple upload app that generates the pre-signed URL for the upload and receives the notifications over an SQS queue. While you can include any HTTP endpoint at the SNS topic that will receive the notifications and you could direct them right into your app, using an SQS queue makes it less likely that we will lose this notification due to a failure on our end. If you never used SQS before, [you can read a full tutorial in Ruby here]({post_url 2014-09-01-make-the-most-of-sqs}).

To avoid setup complications, we'll also use a [CloudFormation](http://aws.amazon.com/cloudformation/) template to create the bucket, configure it, create the SNS topic and the SQS queue. If you have no idea what CloudFormations are, they're templates where you can define resources to be created by Amazon (or some other custom resource provider) that help you create collections of related resources from a single template file instead of manually going through the UI and creating them or making API calls to do it. Long story short, if you're using AWS but not CloudFormations you're wasting a lot of time and resources manually creating all of this stuff, [I also wrote a bit about CloudFormations here]({post_url 2014-08-16-custom-cloud-formation-resources-in-ruby}).

## AWS Setup

The first step is creating all the AWS resources required to perform the upload and send notifications. If we weren't using a CloudFormation template to handle this, we would have to go through the tedious process of setting up each piece in separate and then trying it out, which is incredibly error prone.

But since we *are* using CloudFormation, let's look at the template we have and what each part of it is doing:

{% highlight javascript %}

{% endhighlight %}







...
