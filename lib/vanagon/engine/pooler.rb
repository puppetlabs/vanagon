require 'vanagon/engine/base'

class Vanagon
  class Engine
    class Pooler < Base
      attr_reader :token

      # The vcloud_name is required to use the pooler engine
      def initialize(platform, target = nil)
        @pooler = "http://vmpooler.delivery.puppetlabs.net"
        @token = load_token
        super
        @required_attributes << "vcloud_name"
      end

      # This method loads the pooler token from one of two locations
      # @return [String, nil] token for use with the vmpooler
      def load_token
        token = ENV['VMPOOLER_TOKEN'] || ENV['VMPOOL_TOKEN']
        if token.nil?
          token_file = File.expand_path("~/.vanagon-token")
          if File.exist?(token_file)
            token = File.open(token_file).read.chomp
          end
        end
        token
      end

      # This method is used to obtain a vm to build upon using the Puppet Labs'
      # vmpooler (https://github.com/puppetlabs/vmpooler)
      # @raise [Vanagon::Error] if a target cannot be obtained
      def select_target
        response = Vanagon::Utilities.http_request(
          "#{@pooler}/vm",
          'POST',
          '{"' + @platform.vcloud_name + '":"1"}',
          { 'X-AUTH-TOKEN' => @token }
        )
        if response and response["ok"]
          @target = response[@platform.vcloud_name]['hostname'] + '.' + response['domain']
          Vanagon::Driver.logger.info "Reserving #{@target} (#{@platform.vcloud_name}) [#{@token ? 'token used' : 'no token used'}]"

          tags = {
            'tags' => {
              'jenkins_build_url' => ENV['BUILD_URL'],
              'project' => ENV['JOB_NAME'] || 'vanagon',
              'created_by' => ENV['USER'] || ENV['USERNAME'] || 'unknown'
            }
          }

          response_tag = Vanagon::Utilities.http_request(
            "#{@pooler}/vm/#{response[@platform.vcloud_name]['hostname']}",
            'PUT',
            tags.to_json,
            { 'X-AUTH-TOKEN' => @token }
          )
        else
          raise Vanagon::Error, "Something went wrong getting a target vm to build on, maybe the pool for #{@platform.vcloud_name} is empty?"
        end
      end

      # This method is used to tell the vmpooler to delete the instance of the
      # vm that was being used so the pool can be replenished.
      def teardown
        response = Vanagon::Utilities.http_request(
          "#{@pooler}/vm/#{@target}",
          "DELETE",
          nil,
          { 'X-AUTH-TOKEN' => @token }
        )
        if response and response["ok"]
          Vanagon::Driver.logger.info "#{@target} has been destroyed"
          puts "#{@target} has been destroyed"
        else
          Vanagon::Driver.logger.info "#{@target} could not be destroyed"
          warn "#{@target} could not be destroyed"
        end
      rescue Vanagon::Error => e
        Vanagon::Driver.logger.info "#{@target} could not be destroyed (#{e.message})"
        warn "#{@target} could not be destroyed (#{e.message})"
      end
    end
  end
end
