class Vanagon
  module Utilities

    def get_md5sum(file)
      require 'digest'
      Digest::MD5.file(file).hexdigest.to_s
    end

    def curl(url, type)
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
        fail "ACTION: #{type} not supported by #curl method. Maybe you should add it?"
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
      flags = "-rHlv -O --no-perms --no-owner --no-group"
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

    def fetch_source(url, md5sum, workdir)
      file = download_file(url, workdir)
      puts "verifying file: #{file} against md5sum: '#{md5sum}'"
      verify_file(file, md5sum)
      file
    end

    def download_file(url, workdir)
      require 'net/http'
      require 'uri'
      uri = URI.parse(url)
      target_file = File.basename(uri.path)

      case uri.scheme
      when 'http', 'https'
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new(uri)

          http.request request do |response|
            open(File.join(workdir, target_file), 'w') do |io|
              response.read_body do |chunk|
                io.write(chunk)
              end
            end
          end
        end
      end
      File.join(workdir, target_file)
    end

    def verify_file(file, md5)
      actual = get_md5sum(file)
      unless md5 == actual
        fail "Unable to verify '#{file}'. Expected: '#{md5}', got: '#{actual}'"
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

    def get_extension(source)
      extension_match = source.match(/.*(\.tar\.gz|\.tgz|\.gem|\.tar\.bz)/)
      unless extension_match
        fail "Unrecognized extension for '#{source}'. Don't know how to extract this format. Please teach me."
      end

      extension_match[1]
    end

    def extract_source(source)
      extension = get_extension(source)

      case extension
      when '.tar.gz', '.tgz'
        return "gunzip -c '#{source}' | tar xf -"
      when '.gem'
        # Don't need to unpack gems
        return nil
      else
        fail "Extraction unimplemented for '#{extension}' in source '#{source}'. Please teach me."
      end
    end

    def get_dirname(source)
      extension = get_extension(source)

      case extension
      when '.tar.gz', '.tgz'
        return source.chomp(extension)
      when '.gem'
        # Because we cd into the source dir, using ./ here avoids special casing gems in the Makefile
        return './'
      else
        fail "Don't know how to guess dirname for '#{source}' with extension: '#{extension}'. Please teach me."
      end
    end

    # Return the ref type of HEAD on the current branch
    def git_ref_type
      git = ex('which git').chomp
      ex("#{git} cat-file -t #{git_describe}").strip
    end

    # Return information about the current tree, using `git describe`, ready for
    # further processing.
    #
    # Returns an array of one to four elements, being:
    # * version (three dot-joined numbers, leading `v` stripped)
    # * the string 'rcX' (if the last tag was an rc release, where X is the rc number)
    # * commits (string containing integer, number of commits since that version was tagged)
    # * dirty (string 'dirty' if local changes exist in the repo)
    def git_describe_version
      return nil unless is_git_repo and raw = run_git_describe_internal
      # reprocess that into a nice set of output data
      # The elements we select potentially change if this is an rc
      # For an rc with added commits our string will be something like '0.7.0-rc1-63-g51ccc51'
      # and our return will be [0.7.0, rc1, 63, <dirty>]
      # For a final with added commits, it will look like '0.7.0-63-g51ccc51'
      # and our return will be [0.7.0, 64, <dirty>]
      info = raw.chomp.split('-')
      if git_ref_type == "tag"
        version_string = info.compact
      elsif info[1].to_s.match('^[\d]+')
        version_string = info.values_at(0, 1, 3).compact
      else
        version_string = info.values_at(0, 1, 2, 4).compact
      end
      version_string
    end

    # This is a stub to ease testing...
    def run_git_describe_internal
      Pkg::Util.in_project_root do
        raw = Pkg::Util::Execution.ex("#{GIT} describe --tags --dirty 2>#{DEVNULL}")
        $?.success? ? raw : nil
      end
    end

    def get_dash_version
      if info = git_describe_version
        info.join('-')
      end
    end
  end
end
