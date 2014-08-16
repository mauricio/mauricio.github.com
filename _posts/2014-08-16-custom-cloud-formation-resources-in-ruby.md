---
layout: post
title: AWS Cloud Formations and creating custom resources
subtitle: give your sysadmin a hand
keywords: ruby, aws, cloud-formation, ops, sysadmin
tags:
- ruby
- useful
---

It definitely feels weird to me nowadays that not a lot of people out there are talking about [Cloud Formations](http://aws.amazon.com/cloudformation/). Templated stacks where you can declare all your dependencies in a file and just bring a stack to life with a single upload is definitely one of the most amazing parts of running stuff on top of AWS.

At [Neat](https://www.neat.com/) we have been building our cloud services using Cloud Formations for more than a year now, both new and previous stacks and the improvements in organization and even documentation are visible. You can see the dependencies, configurations, security group and access level rules, databases, cache clusters and even DNS records all configured in a single place.

You can easily change a couple parameters and have a custom environment to try out new stuff and then you can just delete it and have all associated resources deleted as well, there's no need to hunt down all the changes you have done and delete them one by one, once the template is deleted, all resources declared there are deleted as well. It's the safe playground where you can try new stuff and have it be cleaned up by someone else once you're done.

## How does a Cloud Formation template look like?

Let's look at a small example, an SQS queue with a dead letter queue attached to it:

{% highlight javascript %}
{
    "AWSTemplateFormatVersion": "2010-09-09",

    "Description": "Creates our sample queues",

    "Parameters": {
        "Environment": {
            "Description": "Environment in which to manage queues",
            "Type": "String",
            "Default": "qa",
            "AllowedValues": [ "development", "qa", "staging", "production"]
        }
    },

    "Mappings": {
        "EnvironmentOptions": {
            "production": {
              "maxReceiveCount" : 10
            },
            "qa": {
              "maxReceiveCount" : 5
            },
            "development": {
              "maxReceiveCount" : 2
            },
            "staging": {
              "maxReceiveCount" : 10
            }
        }
    },

    "Resources": {
        "IndexerDeadQueue": {
            "Type": "AWS::SQS::Queue",
            "Properties": {
                "ReceiveMessageWaitTimeSeconds": 20,
                "VisibilityTimeout": 600,
                "QueueName": {
                    "Fn::Join": ["-", ["indexer_dead", {
                        "Ref": "Environment"
                    }]]
                }
            }
        },
        "IndexerQueue": {
            "Type": "AWS::SQS::Queue",
            "Properties": {
                "ReceiveMessageWaitTimeSeconds": 20,
                "VisibilityTimeout": 600,
                "QueueName": {
                    "Fn::Join": ["-", ["indexer", {
                        "Ref": "Environment"
                    }]]
                },
                "RedrivePolicy": {
                    "maxReceiveCount": {
                        "Fn::FindInMap": [
                            "EnvironmentOptions",
                            {
                                "Ref": "Environment"
                            },
                            "maxReceiveCount"
                        ]
                    },
                    "deadLetterTargetArn": {
                        "Fn::GetAtt": [ "IndexerDeadQueue", "Arn" ]
                    }
                }
            }
        }
    },

    "Outputs": {
        "IndexerQueue": {
            "Value": {
                "Fn::GetAtt": [ "IndexerQueue", "QueueName" ]
            }
        },
        "IndexerDeadLetterQueue": {
            "Value": {
                "Fn::GetAtt": [ "IndexerDeadQueue", "QueueName" ]
            }
        }
    }
}
{% endhighlight %}

Cloud formation templates are usually made of four parts (they don't have to be in any specific order), `Parameters`, `Mappings`, `Resources` and `Outputs`.

The `Parameters` are options you can set when you're creating or updating the template. These are usually information you'd like to change when creating the stacks, a common option for us is the environment where the stack will run but you could have anything that makes sense here.

`Mappings` are collections of key/value pairs that you can use with the `Fn::FindInMap` intrinsic function (intrinsic functions are functions that can be _called_ at the JSON templates to grab values and perform other basic operations), it's in use here so we can declare a `maxReceiveCount` value depending on the environment that is being used.

## The cloud formation resources

Then we get to the meat of the template, the `Resources`. This is where you declare the AWS resources that make your stack, almost all of the available AWS services are available to be used here so you could have EC2 load balancers, auto scaling groups, RDS databases, ElastiCache clusters, DynamoDB nodes, S3 buckets and everything else, all declared at this single template.

In our case here, we're declaring two SQS queues, let's look at the first one:

{% highlight javascript %}
"IndexerDeadQueue": {
    "Type": "AWS::SQS::Queue",
    "Properties": {
        "ReceiveMessageWaitTimeSeconds": 20,
        "VisibilityTimeout": 600,
        "QueueName": {
            "Fn::Join": ["-", ["indexer_dead", {
                "Ref": "Environment"
            }]]
        }
    }
}
{% endhighlight %}

The first thing you have is the *logical resource id*, this is not the actual resource name (or the queue name, in this case), it's the id for this resource *inside this cloud formation template*, this will be useful when we reference this queue at a different place at this sample template. The name has to be unique across all resources declared at this template and must be alphanumeric only ( `[a-zA-Z0-9]` ).

Once we get inside the resource, we have to declare it's `Type` ([here's a full list of all available types](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)) and then we get to the `Properties` field. Every type has it's own properties ([here are the queue properties](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html)) and you don't have to set an actual value for all of them, you can use parameters, mappings and intrinsic functions to set the property values as well as we're making at the `QueueName` field. Instead of declaring a value directly, we use the `Fn::Join` function to join the base name (`indexer_dead`) with the `Environment` parameter to produce the name (to access the parameter we use another function, `Ref`). If the `Environment` parameter was set to `development`, the final queue name would be `indexer_dead-development` so every environment get's it's own queue.

Now that we've seen the first, let's look at the second resource:

{% highlight javascript %}
"IndexerQueue": {
    "Type": "AWS::SQS::Queue",
    "Properties": {
        "ReceiveMessageWaitTimeSeconds": 20,
        "VisibilityTimeout": 600,
        "QueueName": {
            "Fn::Join": ["-", ["indexer", {
                "Ref": "Environment"
            }]]
        },
        "RedrivePolicy": {
            "maxReceiveCount": {
                "Fn::FindInMap": [
                    "EnvironmentOptions",
                    {
                        "Ref": "Environment"
                    },
                    "maxReceiveCount"
                ]
            },
            "deadLetterTargetArn": {
                "Fn::GetAtt": [ "IndexerDeadQueue", "Arn" ]
            }
        }
    }
}  
{% endhighlight %}

Again we have an SQS queue being declared but now there is another property, `RedrivePolicy`. This property allows us to declare the maximum number of times a message can be received and the target queue to where this message should be sent once it reaches this limit. So, if our systems fail to process this message an specific number of times, the queue itself should give up this message and send it to the dead letter queue were we can later verify what's going on.

To do this we use two intrinsic functions, the `Fn::FindInMap` function to get the `maxReceiveCount` value for the current environment and then the `Fn::GetAtt` function to get the `Arn` value for the dead letter queue. Every resource declares a group of properties that are available for `Fn::GetAtt` calls, whenever you need to reference specific values from other resources inside your cloud formation template, check their documentation and see what values they produce when given to a `Ref` or `Fn::GetAtt` call.

Creating environment specific mappings helps you fine tune your configuration options for every environment and simplify figuring out which values go where instead of manually updating parameters whenever you create a new cloud formation. While parameters are useful, it's much harder to manage and see the changes made when uploading or updating cloud formation stacks, so prefer mappings whenever possible.

## Outpus - publishing interesting information about your stack

And we're finally at the end of the template, where we declare the `Outputs`, let's look at them:

{% highlight javascript %}
"Outputs": {
    "IndexerQueue": {
        "Value": {
            "Fn::GetAtt": [ "IndexerQueue", "QueueName" ]
        }
    },
    "IndexerDeadLetterQueue": {
        "Value": {
            "Fn::GetAtt": [ "IndexerDeadQueue", "QueueName" ]
        }
    }
}
{% endhighlight %}

Outputs are information you publish about your stack, this could be anything, mappings, parameters, resource properties or just a hardcoded value. But the main use of this is publishing information about the resources you created so someone else can consume them.

In our example, we're exporting the queue names for the queues we're creating here.

Why?

Because applications that want to consume these queues don't have to hardcode their names anymore, they can just pull the information out of the Cloud Formation stack directly and use that. Let's look at some Ruby code using the [aws-sdk](https://github.com/aws/aws-sdk-ruby) to do it:

{% highlight ruby %}
cf = AWS::CloudFormation.new
stack = cf.stacks["queues-development"]
outputs = stack.outputs.inject({}) do |acc, output|
  acc[output.key] = output.value
  acc
end
=> {"IndexerQueue" => "indexer-development", "IndexerDeadLetterQueue" => "indexer_dead-development"}
{% endhighlight %}

And once they pull the outputs from the cloud formation, they can grab the actual queues and start pushing and pulling messages to them. This way you could change the queue names and not care about what would happen to the apps, they they would rely on the output names (`IndexerQueue` and `IndexerDeadLetterQueue`) instead of hardcoding the actual names there. You could even just not declare names for these queues at all and the Cloud Formation would provide unique names for them for you.

## Cloud formations FTW!

Let's list the advantages first:

* Single template to declare your stack (or part of it);
* JSON format, fits nicely to version control tools;
* Allows for parametrization and specific configurations on a per-environment basis (by using mappings with environment names);
* Includes a huge collection of available resources by AWS itself;

The main disadvantage is that not all options are available. For instance, you can't subscribe an SQS queue to an SNS topic if the topic already exists or if it was created somewhere else that's where the queue is being declared. Also, even when you can subscribe (right at the SNS resource declaration) you can't set parameters to it like the `raw subscription` that removes the SNS envelope from the message.

And this is where our [cfn-bridge](https://github.com/TheNeatCompany/cfn-bridge) project comes into play. When you start building everything with cloud formations, having to manually create resources feels like going back in time but since not every we would have to do it anyway, right?

Wrong!

Cloud Formations have support for [custom resource creation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/crpg-walkthrough.html) where you can declare an app that will receive notifications from an SNS topic and will handle the _custom resource creation_ for you and that's exactly what we did.

In our case, we needed a solution where we could send a message to a single place and have it distribuited to an unknown number of consumers. As expected, SNS was exactly the solution we were looking for, but we needed something that would allow us to subscribe SQS queues to the topic any time instead of having to declare all the subscribers at the same place as the SNS topic. Since these were different applications with their own Cloud Formation stacks, we couldn't merge them all together, we needed something that would allow us to subscribe to the topic after the fact, but there was no cloud formation resource to do that.

The first option was to give it up and declare all queues together anyway, not ideal or clean, but you have to do what you have to do. After digging a bit around and [finding AWS's own Python custom resource provider](https://github.com/aws/aws-cfn-resource-bridge) we thought, why can't we do this as well?

And there we went building our own custom provider solution and including the resource that [subscribes an SQS queue to an SNS topic after the fact](https://github.com/TheNeatCompany/cfn-bridge/blob/master/lib/cloud_formation/bridge/resources/subscribe_queue_to_topic.rb).

Different from AWS's solution that's more inclined towards getting the user to define all operations, our goal with this gem is to build a collection of useful custom resources that can be shared for the whole community using cloud formations. While we're at only two resources at this point, there are definitely other needs we're seeing as we progress towards using Cloud Formations more and more (like IAM resources) and we hope this will be useful for others as well.

If you're using cloud formations and are missing functionality that is available at the APIs but not as cloud formation resources, you're welcome to contribute them to the project as well. The the [gem's README](https://github.com/TheNeatCompany/cfn-bridge/blob/master/README.md), fork it and send your contributions.
