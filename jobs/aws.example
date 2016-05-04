#!/usr/bin/env ruby

#jobs/aws.rb

require './lib/dashing_aws'

dashing_aws = DashingAWS.new({
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRECT_ACCESS_KEY'],
})

reserved_normalization_factor = {
    "micro" => 0.5,
    "small" => 1,
    "medium" => 2,
    "large" => 4,
    "xlarge" => 8,
    "2xlarge" => 16,
    "4xlarge" => 32,
    "8xlarge" => 64
}

# See documentation here for cloud watch API here: https://github.com/aws/aws-sdk-ruby/blob/af638994bb7d01a8fd0f8a6d6357567968638100/lib/aws/cloud_watch/client.rb
# See documentation on various metrics and dimensions here: http://docs.aws.amazon.com/AWSEC2/2011-07-15/UserGuide/index.html?using-cloudwatch.html

# Note that Amazon charges [$0.01 per 1000 reqeuests](http://aws.amazon.com/pricing/cloudwatch/),
# so:
#
# | frequency | $/month/stat |
# |:---------:|:------------:|
# |     1m    |     $0.432   |
# |    10m    |     $0.043   |
# |     1h    |     $0.007   |
#
# In the free tier, stats are only available for 5m intervals, so querying more often than
# once every 5 minutes is kind of pointless.  You've been warned. :)
#

SCHEDULER.every '5m', :first_in => 0 do |job|
    # Get the ec2 instances
    ec2_instance_collection = dashing_aws.getEc2Instances
    ec2_instances_status = dashing_aws.getEc2InstanceStatus

    # EC2 CPU Stats
    ec2_instances = ec2_instance_collection.map(){|instance|
        type_split = instance.instance_type.match(/(.*)\.(.*)/)
        status = ec2_instances_status.find {|i| i[:instance_id] == instance.id }

        {
            instance_id: instance.instance_id,
            region: 'us-east-1',
            name: instance.tags['Name'],
            avatar: instance.tags['avatar'],
            role: instance.tags['role'],
            project: instance.tags['project'],
            instance_type: instance.instance_type,
            family: type_split[1],
            normalization_factor: reserved_normalization_factor[type_split[2]],
            status: instance.status,
            events_set: status[:events_set],
            system_status: status[:system_status],
            instance_status: status[:instance_status]
        }
    }

    ec2_cpu_series = []
    ec2_instances.each do |item|
        cpu_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "CPUUtilization", 'AWS/EC2', :average, min_y: ENV['AWS_EC2_CPU_MIN'])
        if cpu_data
            cpu_data[:name] = item[:name]
            ec2_cpu_series.push cpu_data
        end
    end

    ec2_mem_series = []
    ec2_instances.each do |item|
        mem_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "MemoryUtilization", 'System/Linux', :average, min_y: ENV['AWS_EC2_MEM_MIN'])
        if mem_data
            mem_data[:name] = item[:name]
            ec2_mem_series.push mem_data
        end
    end

    ec2_hdd_series = []
    ec2_instances.each do |item|
        # TODO The the metrics dimensions from list_metrics mathod
        options = {
            dimensions: [
                {name: "InstanceId", value: item[:instance_id]},
                {name: "MountPath", value: "/"},
                {name: "Filesystem", value: "/dev/xvda1"}
            ],
            min_y: ENV['AWS_EC2_HDD_MIN']
        }

        hdd_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "DiskSpaceUtilization", 'System/Linux', :average, options)
        if hdd_data
            hdd_data[:name] = item[:name]
            ec2_hdd_series.push hdd_data
        end
    end


    # RDS CPU Stats
    rds_instances = dashing_aws.getRdsInstances
    rds_instances = rds_instances.map(){|instance|
        {
            instance_id: instance.db_instance_id,
            region: 'us-east-1',
            name: instance.db_instance_id
        }
    }

    rds_cpu_series = []
    rds_instances.each do |item|
        cpu_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "CPUUtilization", 'AWS/RDS', :average)
        cpu_data[:name] = item[:name]
        rds_cpu_series.push cpu_data
    end

    # RESERVED
    ec2_reserved_instances = dashing_aws.getEc2ReservedInstances
    ec2_reserved_instances = ec2_reserved_instances.map() do |instance|
        type_split = instance.instance_type.match(/(.*)\.(.*)/)

        {
            availability_zone: instance.availability_zone,
            instance_type: instance.instance_type,
            instance_count: instance.instance_count,
            start: instance.start,
            finish: instance.start + instance.duration.seconds,
            duration: instance.duration,
            state: instance.state,
            family: type_split[1],
            normalization_factor: reserved_normalization_factor[type_split[2]]
        }
    end

    instances_nf_stats = ec2_instances.reduce(Hash.new 0) do |r, item|
        if item[:status] == :running and item[:normalization_factor]
            r[item[:family]] -= item[:normalization_factor]
        end
        r
    end

    reserved_nf_stats = ec2_reserved_instances.reduce(Hash.new 0) do |r, item|
        if item[:state] == "active" and item[:normalization_factor]
            r[item[:family]] += item[:normalization_factor] * item[:instance_count]
        end
        r
    end

    per_family_nf = instances_nf_stats.merge(reserved_nf_stats) {|key,val1,val2| val1+val2}

    # ESTIMATED CHARGES
    charges_options = {
       dimensions: [{ name:"Currency", value: "USD" }]
    }
    charges = dashing_aws.getInstanceStats(nil, 'us-east-1', "EstimatedCharges", 'AWS/Billing', :average, charges_options)
    charges = charges[:data].first[:y]

    # If you're using the Rickshaw Graph widget: https://gist.github.com/jwalton/6614023
    send_event "ec2-aws-cpu", { series: ec2_cpu_series }
    send_event "ec2-aws-mem", { series: ec2_mem_series }
    send_event "ec2-aws-hdd", { series: ec2_hdd_series }
    send_event "rds-aws-cpu", { series: rds_cpu_series }
    send_event "ec2-aws-reserved", { stats: per_family_nf.to_a }
    send_event "billing-aws-estimatedcharges", { current: charges }
    send_event "ec2-aws-status", { instances: ec2_instances }

    # If you're just using the regular Dashing graph widget:
    # send_event "aws-cpu-server1", { points: cpu_series[0][:data] }
    # send_event "aws-cpu-server2", { points: cpu_series[1][:data] }
    # send_event "aws-cpu-server3", { points: cpu_series[2][:data] }

end # SCHEDULER
