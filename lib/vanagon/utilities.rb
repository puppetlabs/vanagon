require 'vanagon/errors'
require 'net/http'
require 'uri'
require 'json'
require 'digest'
require 'erb'
require 'timeout'
# This stupid library requires a capital 'E' in its name
# but it provides a wealth of useful constants
require 'English'
require 'vanagon/extensions/string'
require 'vanagon/logger'
require 'vanagon/utilities/extra_files_signer'

class Vanagon
  module Utilities
    extend self

    # Utility to get the md5 sum of a file
    #
    # @deprecated Please use #get_sum instead, this will be removed in a future vanagon release.
    # @param file [String] file to md5sum
    # @return [String] md5sum of the given file
    def get_md5sum(file)
      get_sum(file, 'md5')
    end

    # Generic file summing utility
    #
    # @param file [String] file to sum
    # @param type [String] type of sum to provide, defaults to md5
    # @return [String] sum of the given file
    # @raise [RuntimeError] raises an exception if the given sum type is not supported
    def get_sum(file, type = 'md5')
      Digest.const_get(type.upcase).file(file).hexdigest.to_s

    # If Digest::const_get fails, it'll raise a LoadError when it tries to
    # pull in the subclass `type`. We catch that error, and fail instead.
    rescue LoadError
      fail "Don't know how to produce a sum of type: '#{type}' for '#{file}'"
    end

    # Simple wrapper around Net::HTTP. Will make a request of the given type to
    # the given url and return the response object
    #
    # @param url [String] The url to make the request against (needs to be parsable by URI
    # @param type [String] One of the supported request types (currently 'get', 'post', 'delete')
    # @param payload [String] The request body data payload used for POST and PUT
    # @param header [Hash] Send additional information in the HTTP request header
    # @return [Net::HTTPAccepted] The response object
    # @raise [RuntimeError, Vanagon::Error] an exception is raised if the
    # action is not supported, or if there is a problem with the http request
    def http_request_generic(url, type, payload = {}.to_json, header = nil) # rubocop:disable Metrics/AbcSize
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      case type.downcase
      when "get"
        request = Net::HTTP::Get.new(uri.request_uri)
      when "post"
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = payload
      when "put"
        request = Net::HTTP::Put.new(uri.request_uri)
        request.body = payload
      when "delete"
        request = Net::HTTP::Delete.new(uri.request_uri)
      else
        fail "ACTION: #{type} not supported by #http_request method. Maybe you should add it?"
      end

      # Add any headers to the request
      if header && header.is_a?(Hash)
        header.each do |key, val|
          request[key] = val
        end
      end

      http.request(request)
    rescue Errno::ETIMEDOUT, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
      EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      raise Vanagon::Error.wrap(e, "Problem reaching #{url}. Is #{uri.host} down?")
    end

    # uses http_request_generic and returns the body as parsed by JSON.
    # @param url [String] The url to make the request against (needs to be parsable by URI
    # @param type [String] One of the supported request types (currently 'get', 'post', 'delete')
    # @param payload [String] The request body data payload used for POST and PUT
    # @param header [Hash] Send additional information in the HTTP request header
    # @return [Hash] The response in JSON format
    # @raise [RuntimeError, Vanagon::Error] an exception is raised if the response
    # body cannot be parsed as JSON
    def http_request(url, type, payload = {}.to_json, header = nil)
      response = http_request_generic(url, type, payload, header)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Vanagon::Error.wrap(e, "#{url} handed us a response that doesn't look like JSON.")
    end

    # uses http_request_generic and returns the response code.
    # @param url [String] The url to make the request against (needs to be parsable by URI
    # @param type [String] One of the supported request types (currently 'get', 'post', 'delete')
    # @param payload [String] The request body data payload used for POST and PUT
    # @param header [Hash] Send additional information in the HTTP request header
    # @return [String] The response code eg 202, 200 etc
    def http_request_code(url, type, payload = {}.to_json, header = nil)
      response = http_request_generic(url, type, payload, header)
      response.code
    end

    # Similar to rake's sh, the passed command will be executed and an
    # exception will be raised on command failure. However, in contrast to
    # rake's sh, this method returns the output of the command instead of a
    # boolean.
    #
    # @param command [String] The command to be executed
    # @return [String] The standard output of the executed command
    # @raise [Vanagon::Error] If the command fails an exception is raised
    def ex(command)
      ret = %x(#{command})
      unless $CHILD_STATUS.success?
        raise Vanagon::Error, "'#{command}' did not succeed"
      end
      ret
    end

    # Similar to the command-line utility which, the method will search the
    # PATH for the passed command and return the full path to the command if it
    # exists.
    #
    # @param command [String] Command to search for on PATH
    # @param required [true, false] Whether or not to raise an exception if the command cannot be found
    # @return [String, false] Returns either the full path to the command or false if the command cannot be found
    # @raise [RuntimeError] If the command is required and cannot be found
    def find_program_on_path(command, required = true)
      extensions = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path_elem|
        extensions.each do |ext|
          location = File.join(path_elem, "#{command}#{ext}")
          return location if FileTest.executable?(location)
        end
      end

      if required
        fail "Could not find '#{command}'. Please install (or ensure it is on $PATH), and try again."
      else
        return false
      end
    end
    alias_method :which, :find_program_on_path

    # Method to retry a ruby block and fail if the command does not succeed
    # within the number of tries and timeout.
    #
    # @param tries [Integer] number of times to try calling the block
    # @param timeout [Integer] number of seconds to run the block before timing out
    # @return [true] If the block succeeds, true is returned
    # @raise [Vanagon::Error] if the block fails after the retries are exhausted, an error is raised
    def retry_with_timeout(tries = 5, timeout = 1, &blk)
      error = nil
      tries.to_i.times do
        Timeout::timeout(timeout.to_i) do
          yield
          return true
        rescue StandardError => e
          VanagonLogger.error 'An error was encountered evaluating block. Retrying..'
          error = e
        end
      end

      message = "Block failed maximum number of #{tries} tries"
      unless error.nil?
        message += "\n with error #{error.message}" + "\n#{error.backtrace.join("\n")}"
      end
      message += "\nExiting..."
      raise error, message unless error.nil?
      raise Vanagon::Error, "Block failed maximum number of #{tries} tries"
    end

    # Sends the desired file/directory to the destination using rsync
    #
    # @param source [String] file or directory to send
    # @param target [String] ssh host to send to (user@machine)
    # @param dest [String] path on target to place the source
    # @param extra_flags [Array] any additional flags to pass to rsync
    # @param port [Integer] Port number for ssh (default 22)
    # @return [String] output of rsync command
    def rsync_to(source, target, dest, port = 22, extra_flags = ["--ignore-existing"])
      rsync = find_program_on_path('rsync')
      flags = "-rHlv --no-perms --no-owner --no-group"
      unless extra_flags.empty?
        flags << " " << extra_flags.join(" ")
      end
      ex("#{rsync} -e '#{ssh_command(port)}' #{flags} #{source} #{target}:#{dest}")
    end

    # Hacky wrapper to add on the correct flags for ssh to be used in ssh and rsync methods
    #
    # @param port [Integer] Port number for ssh (default 22)
    # @return [String] start of ssh command, including flags for ssh keys
    def ssh_command(port = 22)
      ssh = find_program_on_path('ssh')
      args = ENV['VANAGON_SSH_KEY'] ? " -i #{ENV['VANAGON_SSH_KEY']}" : ""
      args << " -p #{port} "
      args << " -o UserKnownHostsFile=/dev/null"
      args << " -o StrictHostKeyChecking=no"
      args << " -o ForwardAgent=yes" if ENV['VANAGON_SSH_AGENT']
      return ssh + args
    end

    # Retrieves the desired file/directory from the destination using rsync
    #
    # @param source [String] path on target to retrieve from
    # @param target [String] ssh host to retrieve from (user@machine)
    # @param dest [String] path on local host to place the source
    # @param port [Integer] port number for ssh (default 22)
    # @param extra_flags [Array] any additional flags to pass to rsync
    # @return [String] output of rsync command
    def rsync_from(source, target, dest, port = 22, extra_flags = [])
      rsync = find_program_on_path('rsync')
      flags = "-rHlv -O --no-perms --no-owner --no-group"
      unless extra_flags.empty?
        flags << " " << extra_flags.join(" ")
      end
      ex("#{rsync} -e '#{ssh_command(port)}' #{flags} #{target}:#{source} #{dest}")
    end

    # Runs the command on the given host via ssh call
    #
    # @param target [String] ssh host to run command on (user@machine)
    # @param command [String] command to run on the target
    # @param port [Integer] port number for ssh (default 22)
    # @param return_command_output [Boolean] whether or not command output should be returned
    # @return [true, String] Returns true if the command was successful or the
    #                        output of the command if return_command_output is true
    # @raise [RuntimeError] If there is no target given or the command fails an exception is raised
    def remote_ssh_command(target, command, port = 22, return_command_output: false)
      VanagonLogger.info "Executing '#{command}' on '#{target}'"
      if return_command_output
        ret = %x(#{ssh_command(port)} -T #{target} '#{command.gsub("'", "'\\\\''")}').chomp
        if $CHILD_STATUS.success?
          return ret
        else
          raise "Remote ssh command (#{command}) failed on '#{target}'."
        end
      else
        Kernel.system("#{ssh_command(port)} -T #{target} '#{command.gsub("'", "'\\\\''")}'")
        $CHILD_STATUS.success? or raise "Remote ssh command (#{command}) failed on '#{target}'."
      end
    end

    # Runs the command on the local host
    #
    # @param command [String] command to run locally
    # @param return_command_output [Boolean] whether or not command output should be returned
    # @return [true, String] Returns true if the command was successful or the
    #                        output of the command if return_command_output is true
    # @raise [RuntimeError] If the command fails an exception is raised
    def local_command(command, return_command_output: false)
      clean_environment do
        VanagonLogger.info "Executing '#{command}' locally"
        if return_command_output
          ret = %x(#{command}).chomp
          if $CHILD_STATUS.success?
            return ret
          else
            raise "Local command (#{command}) failed."
          end
        else
          Kernel.system(command)
          $CHILD_STATUS.success? or raise "Local command (#{command}) failed."
        end
      end
    end

    def clean_environment(&block)
      return Bundler.with_clean_env(&block) if defined?(Bundler)
      yield
    end
    private :clean_environment

    # Helper method that takes a template file and runs it through ERB
    #
    # @param erbfile [String] template to be evaluated
    # @param b [Binding] binding to evaluate the template under
    # @return [String] the evaluated template
    def erb_string(erbfile, b = binding)
      template = File.read(erbfile)
      message  = ERB.new(template, trim_mode: "-")
      message.result(b)
        .gsub(/[\n]+{3,}/, "\n\n")
        .squeeze("\s")
    end

    # Helper method that takes a template and writes the evaluated contents to a file on disk
    #
    # @param erbfile [String]
    # @param outfile [String]
    # @param remove_orig [true, false]
    # @param opts [Hash]
    def erb_file(erbfile, outfile = nil, remove_orig = false, opts = { :binding => binding })
      outfile ||= File.join(Dir.mktmpdir, File.basename(erbfile).sub(File.extname(erbfile), ""))
      output = erb_string(erbfile, opts[:binding])
      File.open(outfile, 'w') { |f| f.write output }
      VanagonLogger.info "Generated: #{outfile}"
      FileUtils.rm_rf erbfile if remove_orig
      outfile
    end
  end
end
