---
layout: post
title: Access denied on S3 if you don't have listing rights
subtitle: stuff you should know about
keywords: aws, s3, objects, errors, ruby
tags:
- useful
---

The AWS SDK for Ruby (at least the V1) has a really nice interface of interacting with objects. While building a new app using it, I had a use case where I would try to find a file on S3 and if the file didn't exist the app would follow a different path. Not finding the file wasn't a bug, it was one of the expected cases for the app and the code would look like this:

{% highlight ruby %}
s3 = AWS::S3.new
bucket = s3.buckets["some-bucket-name"]
object = s3.objects["some-object-path"]

begin
  contents = object.read
  # do something with the contents
rescue AWS::S3::Errors::NoSuchKey
  # do something else here
end
{% endhighlight %}

To do this, I had the following policy for the bucket that this app was using (this is part of a CloudFormation template where an IAM policy is declared):

{% highlight ruby %}
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:GetBucketLocation",
    "s3:GetObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    {
      "Fn::Join": [
        "",
        [
          "arn:aws:s3:::",
          {
            "Ref": "S3Bucket"
          },
          "/*"
        ]
      ]
    }
  ]
}
{% endhighlight %}

These are the only operations the app actually needed, so I continued to write it until I started doing the tests. When the object wasn't found, instead of me receiving a `NoSuchKey` error, I would get an `AWS::S3::AccessDenied`. Given the policy above, it would seem that the current user had enough rights to issue `GetObject` requests to the bucket.

After a bunch of head scratching and searching, I thought maybe I should try to give it `ListBucket` access as well and the policy became:

{% highlight ruby %}
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:ListBucket",
    "s3:GetBucketLocation",
    "s3:GetObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    {
      "Fn::Join": [
        "",
        [
          "arn:aws:s3:::",
          {
            "Ref": "S3Bucket"
          },
          "/*"
        ]
      ]
    }
  ]
}
{% endhighlight %}

And when you think about it for a bit it kind of makes sense. If you actually return a 404 when an item is not found for someone that has no listing rights it's as if they actually *did* have listing rights as they can try and figure out if objects exist or not. If they don't know what kind of access level they have, an access denied could mean both that they tried to access something that wasn't there or that they didn't actually have access.

Kind of weird but at least I won't be scratching my head again because of this.
