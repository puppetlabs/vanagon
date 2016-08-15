require 'vanagon/utilities'
require 'vanagon/component/source/local'
require 'net/http'
require 'uri'

class Vanagon
  class Component
    class Source
      class Http < Vanagon::Component::Source::Local
        include Vanagon::Utilities

        # Accessors :url, :file, :extension, :workdir, :cleanup are inherited from Local
        attr_accessor :sum, :sum_type

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
        # @param sum_type [String] type of sum we are verifying
        # @raise [RuntimeError] an exception is raised is sum is nil
        def initialize(url, sum:, workdir:, sum_type:, **options)
          unless sum
            fail "sum is required to validate the http source"
          end
          unless sum_type
            fail "sum_type is required to validate the http source"
          end
          @url = url
          @sum = sum
          @workdir = workdir
          @sum_type = sum_type
        end

        # Download the source from the url specified. Sets the full path to the
        # file as @file and the @extension for the file as a side effect.
        def fetch
          @file = download(@url)
        end

        def file
          @file ||= fetch
        end

        # Verify the downloaded file matches the provided sum
        #
        # @raise [RuntimeError] an exception is raised if the sum does not match the sum of the file
        def verify # rubocop:disable Metrics/AbcSize
          puts "Verifying file: #{file} against sum: '#{sum}'"
          actual = get_sum(File.join(workdir, file), sum_type)
          return true if sum == actual

          fail "Unable to verify '#{File.join(workdir, file)}': #{sum_type} mismatch (expected '#{sum}', got '#{actual}')"
        end

        # Downloads the file from @url into the @workdir
        # @param target_url [String, URI, Addressable::URI] url of an http source to retrieve with GET
        # @raise [RuntimeError, Vanagon::Error] an exception is raised if the URI scheme cannot be handled
        def download(target_url, target_file = nil, headers = { "Accept-Encoding" => "identity" }) # rubocop:disable Metrics/AbcSize
          uri = URI.parse(target_url.to_s)
          target_file ||= File.basename(uri.path)

          puts "Downloading file '#{target_file}' from url '#{target_url}'"

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(Net::HTTP::Get.new(uri, headers)) do |response|
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
      end
    end
  end
end
