require 'vanagon/engine/base'

class Vanagon
  class Engine
    class Pooler < Base
      attr_reader :token

      # The vmpooler_template is required to use the pooler engine
      def initialize(platform, target = nil)
        @pooler = "http://vmpooler.delivery.puppetlabs.net"
        @token = load_token
        super
        @required_attributes << "vmpooler_template"
        @name = 'pooler'
      end

      # This method loads the pooler token from one of two locations
      # @return [String, nil] token for use with the vmpooler
      def load_token
        if ENV['VMPOOLER_TOKEN']
          token = ENV['VMPOOLER_TOKEN']
        else
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
          '{"' + @platform.vmpooler_template + '":"1"}',
          { 'X-AUTH-TOKEN' => @token }
        )
        if response["ok"]
          @target = response[@platform.vmpooler_template]['hostname'] + '.' + response['domain']
          Vanagon::Driver.logger.info "Reserving #{@target} (#{@platform.vmpooler_template}) [#{@token ? 'token used' : 'no token used'}]"

          tags = {
            'tags' => {
              'jenkins_build_url' => ENV['BUILD_URL'],
              'project' => ENV['JOB_NAME'] || 'vanagon',
              'created_by' => ENV['USER'] || ENV['USERNAME'] || 'unknown'
            }
          }

          Vanagon::Utilities.http_request(
            "#{@pooler}/vm/#{response[@platform.vmpooler_template]['hostname']}",
            'PUT',
            tags.to_json,
            { 'X-AUTH-TOKEN' => @token }
          )
        else
          raise Vanagon::Error, "Something went wrong getting a target vm to build on, maybe the pool for #{@platform.vmpooler_template} is empty?"
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
