require 'vanagon/utilities'
require 'net/http'
require 'uri'

class Vanagon
  class Component
    class Source
      class Http
        include Vanagon::Utilities
        attr_accessor :url, :sum, :file, :extension, :workdir, :cleanup

        # Extensions for files we intend to unpack during the build
        ARCHIVE_EXTENSIONS = ['.tar.gz', '.tgz', '.zip'].freeze

        class << self
          def valid_url?(target_url) # rubocop:disable Metrics/AbcSize
            uri = URI.parse(target_url.to_s)
            return false unless ['http', 'https'].include? uri.scheme

            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
              http.request(Net::HTTP::Head.new(uri)) do |response|
                case response
                when Net::HTTPRedirection
                  # By parsing the location header, we get either an absolute
                  # URI or a URI with a relative `path`. Adding it to `uri`
                  # should correctly update the relative `path` or overwrite
                  # the entire URI if it's absolute.
                  location = URI.parse(response.header['location'])
                  valid_url?(uri + location)
                when Net::HTTPSuccess
                  return true
                else
                  false
                end
              end
            end
          end
        end

        # Constructor for the Http source type
        #
        # @param url [String] url of the http source to fetch
        # @param sum [String] sum to verify the download against
        # @param workdir [String] working directory to download into
        # @raise [RuntimeError] an exception is raised is sum is nil
        def initialize(url, sum:, workdir:, **options)
          unless sum
            fail "sum is required to validate the http source"
          end
          @url = url
          @sum = sum
          @workdir = workdir
        end

        # Download the source from the url specified. Sets the full path to the
        # file as @file and the @extension for the file as a side effect.
        def fetch
          @file = download(@url)
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
        # @param target_url [String, URI, Addressable::URI] url of an http source to retrieve with GET
        # @raise [RuntimeError, Vanagon::Error] an exception is raised if the URI scheme cannot be handled
        def download(target_url, target_file = nil) # rubocop:disable Metrics/AbcSize
          uri = URI.parse(target_url.to_s)
          target_file ||= File.basename(uri.path)

          puts "Downloading file '#{target_file}' from url '#{target_url}'"

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(Net::HTTP::Get.new(uri)) do |response|
              case response
              when Net::HTTPRedirection
                # By parsing the location header, we get either an absolute
                # URI or a URI with a relative `path`. Adding it to `uri`
                # should correctly update the relative `path` or overwrite
                # the entire URI if it's absolute.
                location = URI.parse(response.header['location'])
                download(uri + location, target_file)
              when Net::HTTPSuccess
                open(File.join(@workdir, target_file), 'w') do |io|
                  response.read_body { |chunk| io.write(chunk) }
                end
              else
                fail "Error: #{response.code.to_s}. Unable to get source from #{target_url}"
              end
            end
          end

          target_file

        rescue Errno::ETIMEDOUT, Timeout::Error, Errno::EINVAL,
          Errno::EACCES, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
          raise Vanagon::Error.wrap(e, "Problem downloading #{target_file} from '#{@url}'. Please verify you have the correct uri specified.")
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
              return "unzip '#{@file}' || 7za x -r -tzip -o'#{File.basename(@file, '.zip')}' '#{@file}'"
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
