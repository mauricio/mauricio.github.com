---
layout: post
title: AWS quick tips - taking out your EC2 trash
subtitle: finding and deregistering unused AMIs is a bit tricker than expected
keywords: aws, chef, knife, ruby
tags:
- useful
---

If you use EC2 to run your cloud infrastructure, you are most likely making use of pre-made AMIs for faster provisioning of servers inside of auto-scaling groups. Just like any other release material, from time to time you have to cleanup your older stuff both because the cruft accumulates and also because you're paying for the storage these AMIs take as snapshots at your EC2 account.

## Finding unused AMIs

The first cleanup operation is detecting AMIs that are not being used anywhere at your environment, we can do this quickly with a very small Ruby script that uses the [aws-sdk-v1 gem](https://rubygems.org/gems/aws-sdk-v1) :

{% highlight ruby %}
require 'aws/ec2'
client = AWS::EC2.new # you must have your AWS keys setup correctly for this to work
amis = client.instances.map do |instance|
  begin
    instance.image_id
  rescue AWS::Core::Resource::NotFound
    nil
  end
end.compact.uniq

puts("# Loading available AMIs...")
images = client.images.with_owner("self").sort_by { |i| i.name }
images.each do |image|
  next if amis.include?(image.id)
  fields = []
  fields << image.id
  fields << image.block_device_mappings.values.map(&:snapshot_id).compact.join(',')
  fields << image.name

  puts(fields.join("\t"))
end
{% endhighlight %}

This will produce an output like:

    # Loading available AMIs...
    ami-15903pee	snap-945febdz	java8@2015-08-03-02-50
    ami-841928e0	snap-8117t03b	ubuntu_14_base@2015-04-02-21-35
    ami-1dqde176	snap-33fh5a54	windows-server2012R2-base-2015-08-07

What this script does is first list all AMIs from running instances in your system and then load all AMIs that you own (AMIs you created yourself using the `CreateImage` command). We don't really want to know about public or vendor specific AMIs, only the ones we created ourselves.

Now that you know the AMIs that are not in use, you can just open the AWS console and deregister them, right?

Not really!

## Deregistering AMIs

While the AWS console for AMIs will let you deregister AMIs, it does the wrong thing by default, it deregisters the AMI but will not delete the snapshot associated with it. I was really surprised when I looked at our snapshots and we had hundreds of snapshots there from AMIs that were long gone!

So, instead of just using the AWS console for that, we need a script that will actually delete the snapshots associated with them as it makes little sense to deregister the AMI but keep it's snapshot around.

Here's how it would look like:

{% highlight ruby %}
require 'aws/ec2'
ami_id = ARGV[0]
if ami_id.nil? || ami_id.empty?
  puts("you must provide an AMI ID")
  exit(1)
else
  image = client.images[ami_id]
  snapshots = image.block_device_mappings.values.map(&:snapshot_id).compact
  puts "Deregistering AMI [#{image.name}] with snapshots #{snapshots.inspect}"
  image.deregister
  puts "Image deregistered"
  snapshots.each do |snapshot|
    puts "Deleting snapshot #{snapshot}"
    client.snapshots[snapshot].delete
    puts 'Snapshot deleted'
  end
end
{% endhighlight %}

And this should finally clean up the huge amount of useless AMIs and snapshots you have at your account. It definitely helped me clean up a lot of storage at our account by removing unused stuff.

## If you're using Chef and Knife

If you happen to be using [Chef](https://www.chef.io/chef/) with your own set of `knife` plugins, these scripts are actually knife plugins themselves, so you can just copy them to your own repo:

{% highlight ruby %}
# ami unused
require 'chef/knife'

module KnifeCustom
  class AmiUnused < Chef::Knife

    banner "knife ami unused"

    deps do
      require 'aws/ec2'
    end

    option :progress_comments,
      :long => '--[no-]progress-comments',
      :description => "Include comments about progress, enabled by default",
      :boolean => true,
      :default => true

    option :include_in_use,
      :short => '-U',
      :long => '--include-in-use',
      :description => "Include information about AMIs in-use as well, disabled by default",
      :boolean => true,
      :default => false

    option :snapshot_info,
      :long => '--[no-]snapshot-info',
      :description => "List EBS snapshot information for AMIs, enabled by default",
      :boolean => true,
      :default => true

    option :ami_status,
      :long => '--[no-]ami-status',
      :description => "Show AMI status [in-use|unused], enabled by default",
      :boolean => true,
      :default => true

    def run
      ui.info("# Loading running instances...") if config[:progress_comments]
      amis = client.instances.map do |instance|
        begin
          instance.image_id
        rescue AWS::Core::Resource::NotFound
          nil
        end
      end.compact.uniq

      ui.info("# Loading available AMIs...") if config[:progress_comments]
      images = client.images.with_owner("self").sort_by { |i| i.name }
      images.each do |image|
        next if amis.include?(image.id) && !config[:include_in_use]
        status = amis.include?(image.id) ? "in-use" : "unused"
        fields = []
        fields << status if config[:ami_status]
        fields << image.id
        fields << snapshots_for_image(image).join(',') if config[:snapshot_info]
        fields << image.name

        ui.info(fields.join("\t"))
      end
    end

    def client
      @client ||= AWS::EC2.new
    end

    def snapshots_for_image(image)
      image.block_device_mappings.values.collect(&:snapshot_id).compact
    end
  end
end
{% endhighlight %}

And then the command that deregisters AMIs:

{% highlight ruby %}
require 'chef/knife'

module KnifeCustom

  class AmiDeregister < Chef::Knife

    banner "knife ami deregister AMI_ID"

    deps do
      require 'aws/ec2'
    end

    def run
      ami_id = name_args.first
      if ami_id.nil? || ami_id.empty?
        ui.error("you must provide an AMI ID")
        exit(1)
      else
        image = client.images[ami_id]
        snapshots = image.block_device_mappings.values.map(&:snapshot_id).compact
        ui.info "Deregistering AMI [#{image.name}] with snapshots #{snapshots.inspect}"
        image.deregister
        ui.info "Image deregistered"
        snapshots.each do |snapshot|
          ui.info "Deleting snapshot #{snapshot}"
          client.snapshots[snapshot].delete
          ui.info 'Snapshot deleted'
        end
      end
    end

    def client
      @client ||= AWS::EC2.new
    end

  end

end
{% endhighlight %}

Now enjoy the space you now have available and the amount of money you won't be spending on these useless snapshots!
