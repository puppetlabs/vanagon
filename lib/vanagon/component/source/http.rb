require 'vanagon/utilities'
require 'net/http'
require 'uri'

class Vanagon
  class Component
    class Source
      class Http
        include Vanagon::Utilities
        attr_accessor :url, :sum, :file, :extension, :workdir, :cleanup, :upstream_url

        # Extensions for files we intend to unpack during the build
        ARCHIVE_EXTENSIONS = '.tar.gz', '.tgz', '.zip'

        # Constructor for the Http source type
        #
        # @param url [String] url of the http source to fetch
        # @param sum [String] sum to verify the download against
        # @param workdir [String] working directory to download into
        # @param upstream_url [String] URL of the http source upstream
        # @raise [RuntimeError] an exception is raised is sum is nil
        def initialize(url, sum, workdir, upstream_url)
          unless sum
            fail "sum is required to validate the http source"
          end
          @url = url
          @sum = sum
          @workdir = workdir
          @upstream_url = upstream_url
        end

        # Download the source from the url specified. Sets the full path to the
        # file as @file and the @extension for the file as a side effect.
        def fetch
          @file = download
          @extension = get_extension
        end

        # Verify the downloaded file matches the provided sum
        #
        # @raise [RuntimeError] an exception is raised if the sum does not match the sum of the file
        def verify
          puts "Verifying file: #{@file} against sum: '#{@sum}'"
          actual = get_md5sum(File.join(@workdir, @file))
          unless @sum == actual
            fail "Unable to verify '#{@file}'. Expected: '#{@sum}', got: '#{actual}'"
          end
        end

        # Downloads the file from @url into the @workdir
        #
        # @raise [RuntimeError, Vanagon::Error] an exception is raised if the URI scheme cannot be handled
        # @return filename [String] to work with after download
        def download
          file = attempt_download(@url)
          return file unless file == false
          if  @upstream_url.nil?
            raise Vanagon::Error.wrap("", "Problem downloading file from '#{url}'. Please verify you have the correct uri specified.")
          else
            file = attempt_download(@upstream_url)
            if file
              return file
            else
              raise Vanagon::Error.wrap(e, "Problem downloading file from '#{@url}' and '#{@upstream_url}'. Please verify you have the correct uri specified.")
            end
          end
        end

        # Attmpts to download/fetch sources
        #
        # @param url [String] URL to attempt to download from
        # @return [String, bool] target filename or false
        def attempt_download(url)
          uri = URI.parse(url)
          target_file = File.basename(uri.path)

          case uri.scheme
          when 'http', 'https'
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new(uri)

              http.request request do |response|
                unless response.is_a? Net::HTTPSuccess
                  warn "Error: #{response.code.to_s}. Unable to get source from #{@url}"
                end
                open(File.join(@workdir, target_file), 'w') do |io|
                  response.read_body do |chunk|
                    io.write(chunk)
                  end
                end
              end
            end
          when 'file'
            uri = url.match(/^file:\/\/(.*)$/)
            if uri
              source_file = uri[1]
              target_file = File.basename(source_file)
              FileUtils.cp(source_file, File.join(@workdir, target_file))
              return false
            end
          else
            warn "Unable to download files using the uri scheme '#{uri.scheme}'. Maybe you have a typo or need to teach me a new trick?"
            return false
          end

          target_file

        rescue Errno::ETIMEDOUT, Timeout::Error, Errno::EINVAL, SocketError,
          Errno::EACCES, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
          # This is probably less good as we should bubble up the error
          return false
        end

        # Gets the command to extract the archive given if needed (uses @extension)
        #
        # @param tar [String] the tar command to use
        # @return [String, nil] command to extract the source
        # @raise [RuntimeError] an exception is raised if there is no known extraction method for @extension
        def extract(tar)
          if ARCHIVE_EXTENSIONS.include?(@extension)
            case @extension
            when ".tar.gz", ".tgz"
              return "gunzip -c '#{@file}' | '#{tar}' xf -"
            when ".zip"
              return "unzip '#{@file}' || 7za x -r -tzip -o'#{File.basename(@file, ".zip")}' '#{@file}'"
            end
          else
            # Extension does not appear to be an archive
            return ':'
          end
        end

        # Return the correct incantation to cleanup the source archive and source directory for a given source
        #
        # @return [String] command to cleanup the source
        # @raise [RuntimeError] an exception is raised if there is no known extraction method for @extension
        def cleanup
          if ARCHIVE_EXTENSIONS.include?(@extension)
            return "rm #{@file}; rm -r #{dirname}"
          else
            # Because dirname will be ./ here, we don't want to try to nuke it
            return "rm #{@file}"
          end
        end

        # Returns the extension for @file
        #
        # @return [String] the extension of @file
        def get_extension
          extension_match = @file.match(/.*(#{Regexp.union(ARCHIVE_EXTENSIONS)})/)
          unless extension_match
            if @file.split('.').last.include?('.')
              return '.' +  @file.split('.').last
            else
              # This is the case where the file has no extension
              return @file
            end
          end
          extension_match[1]
        end

        # The dirname to reference when building from the source
        #
        # @return [String] the directory that should be traversed into to build this source
        # @raise [RuntimeError] if the @extension for the @file isn't currently handled by the method
        def dirname
          if ARCHIVE_EXTENSIONS.include?(@extension)
            return @file.chomp(@extension)
          else
            return './'
          end
        end
      end
    end
  end
end
