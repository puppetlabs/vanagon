require 'aws-sdk'
require 'erb'
require 'base64'
require 'vanagon/engine/base'

class Vanagon
  class Engine
    class Ec2 < Base
      attr_accessor :ami, :key_name, :userdata, :key, :key_name, :shutdown_behavior
      attr_accessor :subnet_id, :instance_type

      def initialize(platform, target = nil, **opts) # rubocop:disable Metrics/AbcSize
        super

        @ami = @platform.aws_ami
        @target_user = @platform.target_user
        @subnet_id = @platform.aws_subnet_id
        @userdata = @platform.aws_user_data
        @region = @platform.aws_region || 'us-east-1'
        @key_name = @platform.aws_key_name
        @key = @platform.aws_key
        @instance_type = @platform.aws_instance_type || "t1.micro"
        @required_attributes = ["ssh_port", "aws_ami", "aws_key_name"]
        @shutdown_behavior = @platform.aws_shutdown_behavior

        @ec2 = ::Aws::EC2::Client.new(region: @region)
        @resource = ::Aws::EC2::Resource.new(client: @ec2)
      end

      def name
        'ec2'
      end

      def get_userdata
        unless @userdata.nil?
          Base64.encode64(ERB.new(@userdata).result(binding))
        end
      end

      def instances
        @instances ||= @resource.create_instances({
          image_id: ami,
          min_count: 1,
          max_count: 1,
          key_name: key_name,
          instance_type: instance_type,
          subnet_id: subnet_id,
          user_data: get_userdata,
          monitoring: {
            enabled: false,
          }
        })
      end

      def instance
        @instance ||= instances.first
      end

      def select_target
        $stderr.puts "Instance created id: #{instance.id}"
        $stderr.puts "Created instance waiting for status ok"
        @ec2.wait_until(:instance_status_ok, instance_ids: [instance.id])
        $stderr.puts "Instance running"
        @target = instance.private_ip_address
      rescue ::Aws::Waiters::Errors::WaiterFailed => error
        fail "Failed to wait for ec2 instance to start got error #{error}"
      end

      def teardown
        $stderr.puts "Destroying instance on AWS id: #{instance.id}"
        instances.batch_terminate!
      end
    end
  end
end
