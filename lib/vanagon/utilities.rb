require 'vanagon/errors'
require 'net/http'
require 'uri'
require 'json'
require 'digest'
require 'erb'
require 'timeout'

class Vanagon
  module Utilities

    # Utility to get the md5 sum of a file
    #
    # @param file [String] file to md5sum
    # @return [String] md5sum of the given file
    def get_md5sum(file)
      Digest::MD5.file(file).hexdigest.to_s
    end

    # Generic file summing utility
    #
    # @param file [String] file to sum
    # @param type [String] type of sum to provide
    # @return [String] sum of the given file
    # @raise [RuntimeError] raises an exception if the given sum type is not supported
    def get_sum(file, type)
      case type.downcase
      when 'md5'
        Digest::MD5.file(file).hexdigest.to_s
      when 'sha512'
        Digest::SHA512.file(file).hexdigest.to_s
      else
        fail "Don't know how to produce a sum of type: '#{type}' for '#{file}'."
      end
    end

    # Simple wrapper around Net::HTTP. Will make a request of the given type to
    # the given url and return the body as parsed by JSON.
    #
    # @param url [String] The url to make the request against (needs to be parsable by URI
    # @param type [String] One of the supported request types (currently 'get', 'post', 'delete')
    # @return [Hash] The response body is parsed by JSON and returned
    # @raise [RuntimeError, Vanagon::Error] an exception is raised if the
    # action is not supported, or if there is a problem with the http request,
    # or if the response is not JSON
    def http_request(url, type)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      case type.downcase
      when "get"
      response = http.request(Net::HTTP::Get.new(uri.request_uri))
      when "post"
      response = http.request(Net::HTTP::Post.new(uri.request_uri))
      when "delete"
      response = http.request(Net::HTTP::Delete.new(uri.request_uri))
      else
        fail "ACTION: #{type} not supported by #http_request method. Maybe you should add it?"
      end

      JSON.parse(response.body)

    rescue Errno::ETIMEDOUT, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
      EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      raise Vanagon::Error.wrap(e, "Problem reaching #{url}. Is #{uri.host} down?")
    rescue JSON::ParserError => e
      raise Vanagon::Error.wrap(e, "#{uri.host} handed us a response that doesn't look like JSON.")
    end

    # Similar to rake's sh, the passed command will be executed and an
    # exception will be raised on command failure. However, in contrast to
    # rake's sh, this method returns the output of the command instead of a
    # boolean.
    #
    # @param command [String] The command to be executed
    # @return [String] The standard output of the executed command
    # @raise [RuntimeError] If the command fails an exception is raised
    def ex(command)
      ret = `#{command}`
      unless $?.success?
        raise RuntimeError, "'#{command}' did not succeed"
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
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path_elem|
        location = File.join(path_elem, command)
        return location if FileTest.executable?(location)
      end

      if required
        fail "Could not find '#{command}'. Please install (or ensure it is on $PATH), and try again."
      else
        return false
      end
    end

    # Method to retry a ruby block and fail if the command does not succeed
    # within the number of tries and timeout.
    #
    # @param tries [Integer] number of times to try calling the block
    # @param timeout [Integer] number of seconds to run the block before timing out
    # @return [true] If the block succeeds, true is returned
    # @raise [Vanagon::Error] if the block fails after the retries are exhausted, an error is raised
    def retry_with_timeout(tries = 5, timeout = 1, &blk)
      tries.times do
        Timeout::timeout(timeout) do
          begin
            blk.call
            return true
          rescue
            warn 'An error was encountered evaluating block. Retrying..'
          end
        end
      end

      raise Vanagon::Error.new("Block failed maximum of #{tries} tries. Exiting..")
    end

    # Simple wrapper around git command line executes the given commands and
    # returns the results.
    #
    # @param commands [String] The commands to be run
    # @return [String] The output of the command
    def git(*commands)
      git_bin = find_program_on_path('git')
      %x(#{git_bin} #{commands.join(' ')})
    end

    # Determines if the given directory is a git repo or not
    #
    # @param directory [String] The directory to check
    # @return [true, false] True if the directory is a git repo, false otherwise
    def is_git_repo?(directory = Dir.pwd)
      Dir.chdir(directory) do
        git('rev-parse', '--git-dir', '> /dev/null 2>&1')
        $?.success?
      end
    end

    # Determines a version for the given directory based on the git describe
    # for the repository
    #
    # @param directory [String] The directory to use in versioning
    # @return [String] The version of the directory accoring to git describe
    # @raise [RuntimeError] If the given directory is not a git repo
    def git_version(directory = Dir.pwd)
      if is_git_repo?(directory)
        Dir.chdir(directory) do
          version = git('describe', '--tags', '2> /dev/null').chomp
          if version.empty?
            warn "Directory '#{directory}' cannot be versioned by git. Maybe it hasn't been tagged yet?"
          end
          return version
        end
      else
        fail "Directory '#{directory}' is not a git repo, cannot get a version"
      end
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
    def ssh_command(port = 22 )
      ssh = find_program_on_path('ssh')
      args = ENV['VANAGON_SSH_KEY'] ? " -i #{ENV['VANAGON_SSH_KEY']}" : ""
      args << " -p #{port} "
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
    # @return [true] Returns true if the command was successful
    # @raise [RuntimeError] If there is no target given or the command fails an exception is raised
    def remote_ssh_command(target, command, port = 22 )
      if target
        puts "Executing '#{command}' on #{target}"
        Kernel.system("#{ssh_command(port)} -t -o StrictHostKeyChecking=no #{target} '#{command.gsub("'", "'\\\\''")}'")
        $?.success? or raise "Remote ssh command (#{command}) failed on '#{target}'."
      else
        fail "Need a target to ssh to. Received none."
      end
    end

    # Helper method that takes a template file and runs it through ERB
    #
    # @param erbfile [String] template to be evaluated
    # @param b [Binding] binding to evaluate the template under
    # @return [String] the evaluated template
    def erb_string(erbfile, b = binding)
      template = File.read(erbfile)
      message  = ERB.new(template, nil, "-")
      message.result(b)
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
      puts "Generated: #{outfile}"
      FileUtils.rm_rf erbfile if remove_orig
      outfile
    end
  end
end
