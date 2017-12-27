require 'vanagon/engine/base'
require 'yaml'

class Vanagon
  class Engine
    class Pooler < Base
      attr_reader :token

      # The vmpooler_template is required to use the pooler engine
      def initialize(platform, target = nil, **opts)
        super

        @available_poolers = ["http://vmpooler.delivery.puppetlabs.net", "https://nspooler-service-prod-1.delivery.puppetlabs.net"]
        @token = load_token
        @required_attributes << "vmpooler_template"
      end

      # Get the engine name
      def name
        'pooler'
      end

      # Return the vmpooler template name to build on
      def build_host_name
        if @build_host_template_name.nil?
          validate_platform
          @build_host_template_name = @platform.vmpooler_template
        end

        @build_host_template_name
      end

      # Retrieve the pooler token from an environment variable
      # ("VMPOOLER_TOKEN") or from a number of potential configuration
      # files (~/.vanagon-token or ~/.vmfloaty.yml).
      # @return [String, nil] token for use with the vmpooler
      def load_token
        ENV['VMPOOLER_TOKEN'] || token_from_file
      end

      # a wrapper method around retrieving a vmpooler token,
      # with an explicitly ordered preference for a Vanagon-specific
      # token file or a preexisting vmfoaty yaml file.
      #
      # @return [String, nil] token for use with the vmpooler
      def token_from_file
        read_vanagon_token || read_vmfloaty_token
      end
      private :token_from_file

      # Read a vmpooler token from the plaintext vanagon-token file,
      # as outlined in the project README.
      #
      # @return [String, nil] the vanagon vmpooler token value
      def read_vanagon_token(path = "~/.vanagon-token")
        absolute_path = File.expand_path(path)
        return nil unless File.exist?(absolute_path)

        warn "Reading vmpooler token from: #{path}"
        File.read(absolute_path).chomp
      end
      private :read_vanagon_token

      # Read a vmpooler token from the yaml formatted vmfloaty config,
      # as outlined by the vmfloaty project:
      # https://github.com/briancain/vmfloaty
      #
      # @return [String, nil] the vmfloaty vmpooler token value
      def read_vmfloaty_token(path = "~/.vmfloaty.yml")
        absolute_path = File.expand_path(path)
        return nil unless File.exist?(absolute_path)

        warn "Reading vmpooler token from: #{path}"
        YAML.load_file(absolute_path)['token']
      end
      private :read_vmfloaty_token

      # This method is used to obtain a vm to build upon using the Puppet Labs'
      # vmpooler (https://github.com/puppetlabs/vmpooler) or other pooler technologies
      # leveraging the same API
      # @raise [Vanagon::Error] if a target cannot be obtained
      def select_target
        @available_poolers.each do |current_pooler|
          @pooler = select_target_from(current_pooler)
          break unless @pooler.empty?
        end
        raise Vanagon::Error, "Something went wrong getting a target vm to build on, maybe the pool for #{build_host_name} is empty?" if @pooler.empty?
      end

      # Attempt to provision a host from a specific pooler.
      #
      def select_target_from(pooler) # rubocop:disable Metrics/AbcSize
        response = Vanagon::Utilities.http_request(
          "#{pooler}/vm",
          'POST',
          '{"' + build_host_name + '":"1"}',
          { 'X-AUTH-TOKEN' => @token }
        )
        if response["ok"]
          @target = response[build_host_name]['hostname']
          # The nspooler does not use 'domain' in the response: 'hostname' just returns the fqdn.
          # in the future we should make the two APIs the same in this sense, but for now, just check
          # if 'domain' is a thing and use it if so.
          if response['domain']
            @target += '.' + response['domain']
          end
          Vanagon::Driver.logger.info "Reserving #{@target} (#{build_host_name}) [#{@token ? 'token used' : 'no token used'}]"
          add_tags_to_target(pooler, response[build_host_name]['hostname'])
        else
          pooler = ''
        end
        pooler
      end

      # Add tags to a provisioned target using the pooler API
      #
      def add_tags_to_target(pooler, hostname)
        tags = {
          'tags' => {
            'jenkins_build_url' => ENV['BUILD_URL'],
            'project' => ENV['JOB_NAME'] || 'vanagon',
            'created_by' => ENV['USER'] || ENV['USERNAME'] || 'unknown'
          }
        }
        Vanagon::Utilities.http_request(
          "#{pooler}/vm/#{hostname}",
          'PUT',
          tags.to_json,
          { 'X-AUTH-TOKEN' => @token }
        )
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
          warn "#{@target} has been destroyed"
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
