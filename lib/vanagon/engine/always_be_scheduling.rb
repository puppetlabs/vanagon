require 'json'
require 'vanagon/engine/base'
require 'vanagon/logger'
require 'yaml'

class Vanagon
  class Engine
    # This engine allows build resources to be managed by the ["Always be
    # Scheduling" (ABS) scheduler](https://github.com/puppetlabs/always-be-scheduling)
    #
    # ABS expects to ask `build_host_info` for the needed resources for a build,
    # and to have that return a platform name.  ABS will then acquire the
    # desired build host resources and will later run a vanagon build, passing
    # those resource hostnames in specifically.
    #
    # `build_host_info` will normally use the `hardware` engine when a hardware
    # platform is queried. The `always_be_scheduling` engine's behavior will
    # be invoked instead when:
    #
    # `build_host_info ... --engine always_be_scheduling` is specified on the
    # command-line.
    #
    # Configuration
    # -------------
    #
    # Project platform configurations can specify the platform name to be returned
    # via the `abs_resource_name` attribute. If this is not set but `vmpooler_template`
    # is set, then the `vmpooler_template` value will be used. Otherwise, the
    # platform name will be returned unchanged.
    #
    # Example 1
    # ---------
    #
    # ```
    # platform 'ubuntu-10.04-amd64' do |plat|
    #   plat.vmpooler_template 'ubuntu-1004-amd64'
    # end
    # ```
    #
    # ```
    # $ build_host_info puppet-agent ubuntu-10.04-amd64
    # {"name":"ubuntu-10.04-amd64","engine":"pooler"}
    #
    # $ build_host_info puppet-agent ubuntu-10.04-amd64 --engine always_be_scheduling
    # {"name":"ubuntu-10.04-amd64","engine":"always_be_scheduling"}
    # ```
    #
    #
    # Example 2
    # ---------
    #
    # ```
    # platform 'aix-5.3-ppc' do |plat|
    #   plat.build_host ['aix53-builder-1.example.com']
    #   plat.abs_resource_name 'aix-53-ppc'
    # end
    # ```
    #
    # ```
    # $ build_host_info puppet-agent aix-5.3-ppc
    # {"name":"aix53-builder-1.example.com","engine":"hardware"}
    #
    # $ build_host_info puppet-agent aix-5.3-ppc --engine always_be_scheduling
    # {"name":"aix-53-ppc","engine":"always_be_scheduling"}
    # ```
    #
    #
    # Example 3
    # ---------
    #
    # ```
    # platform 'aix-5.3-ppc' do |plat|
    #   plat.build_host ['aix53-builder-1.example.com']
    #   plat.vmpooler_template
    #   plat.abs_resource_name 'aix-53-ppc'
    # end
    # ```
    #
    # ```
    # $ build_host_info puppet-agent aix-5.3-ppc
    # {"name":"aix53-builder-1.example.com","engine":"hardware"}
    #
    # $ build_host_info puppet-agent aix-5.3-ppc --engine always_be_scheduling
    # {"name":"aix-53-ppc","engine":"always_be_scheduling"}
    # ```
    class AlwaysBeScheduling < Base
      attr_reader :token
      attr_reader :token_vmpooler

      def initialize(platform, target, **opts)
        super

        @available_abs_endpoint = "https://abs-prod.k8s.infracore.puppet.net/api/v2"
        @token_vmpooler = ENV['VMPOOLER_TOKEN']
        @token = load_token
        Vanagon::Driver.logger.debug "AlwaysBeScheduling engine invoked."
      end

      # Get the engine name
      def name
        'always_be_scheduling'
      end

      # return the platform name as the "host" name
      # order of preference: abs_resource_name, vmpooler_template or name
      def build_host_name
        if @platform.abs_resource_name
          @platform.abs_resource_name
        elsif @platform.vmpooler_template
          @platform.vmpooler_template
        else
          @platform.name
        end
      end

      # Retrieve the ABS token from an environment variable
      # ("ABS_TOKEN") or from a number of potential configuration
      # files (~/.vanagon-token or ~/.vmfloaty.yml).
      # @return [String, nil] token for use with the vmpooler
      def load_token
        ENV['ABS_TOKEN'] || token_from_file
      end

      # a wrapper method around retrieving a token,
      # with an explicitly ordered preference for a Vanagon-specific
      # token file or a preexisting vmfoaty yaml file.
      #
      # @return [String, nil] token for use with the vmpooler
      def token_from_file
        read_vanagon_token || read_vmfloaty_token
      end
      private :token_from_file

      # Read an ABS/vmpooler token from the plaintext vanagon-token file,
      # as outlined in the project README.
      # The first line should be the ABS token
      # and the second (optional) line should be the vmpooler token
      # Saves the second line into the @token_vmpooler variable
      #
      # @return [String, nil] the vanagon vmpooler token value
      def read_vanagon_token(path = "~/.vanagon-token")
        absolute_path = File.expand_path(path)
        return nil unless File.exist?(absolute_path)

        VanagonLogger.info "Reading ABS token from: #{path}"
        contents = File.read(absolute_path).chomp
        lines = contents.each_line.map(&:chomp)

        abs = lines.shift
        @token_vmpooler = lines.shift

        VanagonLogger.info "Please add a second line with the vmpooler token to be able to modify or see the VM in floaty/bit-bar" if @token_vmpooler.nil?
        return abs
      end
      private :read_vanagon_token

      # Read a vmpooler token from the yaml formatted vmfloaty config,
      # as outlined by the vmfloaty project:
      # https://github.com/puppetlabs/vmfloaty
      #
      # It returns the top-level token value or the first 'abs' service
      # token value it finds in the services list
      # it sets @token_vmpooler with the optional vmpooler token
      # if the abs services has a vmpooler_fallback, and that service
      # has a token eg
      #
      # TOP-LEVEL DEFINED  => would get only the abs token
      # user: 'jdoe'
      # url: 'https://abs.example.net'
      # token: '456def789'
      #
      # MULTIPLE SERVICES DEFINED => would get the abs token in 'abs-prod' and the vmpooler token in 'vmpooler-prod'
      # user: 'jdoe'
      # services:
      #   abs-prod:
      #     type: 'abs'
      #     url: 'https://abs.example.net/api/v2'
      #     token: '123abc456'
      #     vmpooler_fallback: 'vmpooler-prod'
      #   vmpooler-dev:
      #     type: 'vmpooler'
      #     url: 'https://vmpooler-dev.example.net'
      #     token: '987dsa654'
      #   vmpooler-prod:
      #     type: 'vmpooler'
      #     url: 'https://vmpooler.example.net'
      #     token: '456def789'
      #
      # @return [String, nil] the vmfloaty vmpooler token value
      def read_vmfloaty_token(path = "~/.vmfloaty.yml") # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        absolute_path = File.expand_path(path)
        return nil unless File.exist?(absolute_path)

        yaml_config = YAML.load_file(absolute_path)
        abs_token = nil
        abs_service_name = nil
        if yaml_config['token'] # top level
          abs_token = yaml_config['token']
        elsif yaml_config['services']
          yaml_config['services'].each do |name, value|
            if value['type'] == "abs" && value['token']
              abs_token = value['token']
              abs_service_name = name
              vmpooler_fallback = value['vmpooler_fallback']
              unless vmpooler_fallback.nil? || yaml_config['services'][vmpooler_fallback].nil? || yaml_config['services'][vmpooler_fallback]['token'].nil?
                @token_vmpooler = yaml_config['services'][vmpooler_fallback]['token']
              end
              break
            end
          end
        end
        message = "Reading ABS token from: #{path}"
        if abs_service_name
          message.concat(" for service named #{abs_service_name}")
          if @token_vmpooler.nil?
            message.concat(" but there was no vmpooler_fallback value, please add one if you want to be able to modify the VM via bit-bar/floaty")
          else
            message.concat(" with a vmpooler_fallback token")
          end
        end
        VanagonLogger.info message
        return abs_token
      end
      private :read_vmfloaty_token

      # This method is used to obtain a vm to build upon using Puppet's internal
      # ABS (https://github.com/puppetlabs/always-be-scheduling) which is a level of abstraction for other
      # engines using similar APIs
      # @raise [Vanagon::Error] if a target cannot be obtained
      def select_target
        @pooler = select_target_from(@available_abs_endpoint)
        raise Vanagon::Error, "Something went wrong getting a target vm to build on" if @pooler.empty?
      end

      # Attempt to provision a host from a specific pooler.
      def select_target_from(pooler) # rubocop:disable Metrics/AbcSize
        request_object = build_request_object

        VanagonLogger.info "Requesting VMs with job_id: #{@saved_job_id}.  Will poll for up to an hour."
        #the initial request is always replied with "come back again"
        response = Vanagon::Utilities.http_request_generic(
          "#{pooler}/request",
          'POST',
          request_object.to_json,
          { 'X-AUTH-TOKEN' => @token }
        )

        unless response.code == "202"
          VanagonLogger.info "failed to request ABS with code #{response.code}"
          if valid_json?(response.body)
            response_json = JSON.parse(response.body)
            VanagonLogger.info "reason: #{response_json['reason']}"
          end
          return ''
        end
        response_body = check_queue(pooler, request_object)

        return '' unless response_body["ok"]
        @target = response_body[build_host_name]['hostname']
        Vanagon::Driver.logger.info "Reserving #{@target} (#{build_host_name}) [#{@token ? 'token used' : 'no token used'}]"
        return pooler
      end

      # main loop where the status of the request is checked, to see if the request
      # has been allocated
      def check_queue(pooler, request_object)
        retries = 360 # ~ one hour
        response_body = nil
        begin
          (1..retries).each do |i|
            response = Vanagon::Utilities.http_request_generic(
              "#{pooler}/request",
              'POST',
              request_object.to_json,
              { 'X-AUTH-TOKEN' => @token }
            )
            response_body = validate_queue_status_response(response.code, response.body)
            break if response_body

            sleep_seconds = 10 if i >= 10
            sleep_seconds = i if i < 10
            VanagonLogger.info "Waiting #{sleep_seconds} seconds to check if ABS request has been filled. (x#{i})"

            sleep(sleep_seconds)
          end
        rescue SystemExit, Interrupt
          VanagonLogger.error "\nVanagon interrupted during mains ABS polling. Make sure you delete the requested job_id #{@saved_job_id}"
          raise
        end
        response_body = translated(response_body, @saved_job_id)
        response_body
      end

      def validate_queue_status_response(status_code, body)
        case status_code
        when "200"
          return JSON.parse(body) unless body.empty? || !valid_json?(body)
        when "202"
          return nil
        when "401"
          raise Vanagon::Error, "HTTP #{status_code}: The token provided could not authenticate.\n#{body}"
        when "503"
          return nil
        else
          raise Vanagon::Error, "HTTP #{status_code}: request to ABS failed!\n#{body}"
        end
      end

      # This method is used to tell the ABS to delete the job_id requested
      # otherwise the resources will eventually get allocated asynchronously
      # and will keep running until the end of their lifetime.
      def teardown # rubocop:disable Metrics/AbcSize
        request_object = {
            'job_id' => @saved_job_id,
        }

        response = Vanagon::Utilities.http_request_generic(
          "#{@available_abs_endpoint}/return",
          "POST",
          request_object.to_json,
          { 'X-AUTH-TOKEN' => @token }
        )
        if response && response.body == 'OK'
          Vanagon::Driver.logger.info "#{@saved_job_id} has been scheduled for removal"
          VanagonLogger.info "#{@saved_job_id} has been scheduled for removal"
        else
          Vanagon::Driver.logger.info "#{@saved_job_id} could not be scheduled for removal: #{response.body}"
          VanagonLogger.info "#{@saved_job_id} could not be scheduled for removal"
        end
      rescue Vanagon::Error => e
        Vanagon::Driver.logger.info "#{@saved_job_id} could not be scheduled for removal (#{e.message})"
        VanagonLogger.info "#{@saved_job_id} could not be scheduled for removal (#{e.message})"
      end

      private

      def translated(response_body, job_id)
        vmpooler_formatted_body = { 'job_id' => job_id }

        response_body.each do |host| # in this context there should be only one host
          vmpooler_formatted_body[host['type']] = { 'hostname' => host['hostname'] }
        end
        vmpooler_formatted_body['ok'] = true

        vmpooler_formatted_body
      end

      def build_request_object
        user = ENV['USER'] || ENV['USERNAME'] || 'vanagon'

        @saved_job_id = user + "-" + DateTime.now.strftime('%Q')
        request_object = {
            :resources => { build_host_name => 1 },
            :job       => {
                :id   => @saved_job_id,
                :tags => {
                    :jenkins_build_url => ENV['BUILD_URL'],
                    :project           => ENV['JOB_NAME'] || 'vanagon',
                    :created_by        => user,
                    :user              => user
                },
            },
            :priority => 3, # DO NOT use priority 1 in automated CI runs
        }
        unless @token_vmpooler.nil?
          request_object[:vm_token] = @token_vmpooler
        end
        request_object
      end

      def valid_json?(json)
        JSON.parse(json)
        return true
      rescue TypeError, JSON::ParserError
        return false
      end
    end
  end
end
