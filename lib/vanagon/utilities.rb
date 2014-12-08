class Vanagon
  module Utilities

    def get_md5sum(file)
      require 'digest'
      Digest::MD5.file(file).hexdigest.to_s
    end

    def get_sum(file, type)
      require 'digest'
      case type.downcase
      when 'md5'
        Digest::MD5.file(file).hexdigest.to_s
      when 'sha512'
        Digest::SHA512.file(file).hexdigest.to_s
      end
    end

    def http_request(url, type)
      require 'net/http'
      require 'uri'
      require 'json'
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
    end

    def ex(command)
      ret = `#{command}`
      unless $?.success?
        raise RuntimeError
      end
      ret
    end

    def rsync_to(source, target, dest, extra_flags = ["--ignore-existing"])
      rsync = ex("which rsync").chomp
      flags = "-rHlv --no-perms --no-owner --no-group"
      unless extra_flags.empty?
        flags << " " << extra_flags.join(" ")
      end
      ex("#{rsync} #{flags} #{source} #{target}:#{dest}")
    end

    def rsync_from(source, target, dest, extra_flags = [])
      rsync = ex("which rsync").chomp
      flags = "-rHlv -O --no-perms --no-owner --no-group"
      unless extra_flags.empty?
        flags << " " << extra_flags.join(" ")
      end
      ex("#{rsync} #{flags} #{target}:#{source} #{dest}")
    end

    def remote_ssh_command(target, command)
      if target
        ssh = ex("which ssh").chomp
        puts "Executing '#{command}' on #{target}"
        Kernel.system("#{ssh} -t -o StrictHostKeyChecking=no #{target} '#{command.gsub("'", "'\\\\''")}'")
        $?.success? or raise "Remote ssh command (#{command}) failed on '#{target}'."
      else
        fail "Need a target to ssh to. Received none."
      end
    end

    def erb_string(erbfile, b = binding)
      require 'erb'
      template = File.read(erbfile)
      message  = ERB.new(template, nil, "-")
      message.result(b)
    end

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
