require 'vanagon/utilities'
require 'net/http'
require 'uri'

class Vanagon
  class Component
    class Source
      class Http
        include Vanagon::Utilities
        attr_accessor :url, :sum, :file, :extension, :workdir

        def initialize(url, sum, workdir)
          @url = url
          @sum = sum
          @workdir = workdir
        end

        def fetch
          @file = download
          @extension = get_extension
        end

        def verify
          puts "Verifying file: #{@file} against sum: '#{@sum}'"
          actual = get_md5sum(File.join(@workdir, @file))
          unless @sum == actual
            fail "Unable to verify '#{@file}'. Expected: '#{@sum}', got: '#{actual}'"
          end
        end

        def download
          uri = URI.parse(@url)
          target_file = File.basename(uri.path)

          case uri.scheme
          when 'http', 'https'
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new(uri)

              http.request request do |response|
                open(File.join(@workdir, target_file), 'w') do |io|
                  response.read_body do |chunk|
                    io.write(chunk)
                  end
                end
              end
            end
          end
          target_file
        end

        def extract
          case @extension
          when '.tar.gz', '.tgz'
            return "gunzip -c '#{@file}' | tar xf -"
          when '.gem'
            # Don't need to unpack gems
            return nil
          else
            fail "Extraction unimplemented for '#{@extension}' in source '#{@file}'. Please teach me."
          end
        end

        def get_extension
          extension_match = @file.match(/.*(\.tar\.gz|\.tgz|\.gem|\.tar\.bz)/)
          unless extension_match
            fail "Unrecognized extension for '#{@file}'. Don't know how to extract this format. Please teach me."
          end

          extension_match[1]
        end

        def dirname
          case @extension
          when '.tar.gz', '.tgz'
            return @file.chomp(@extension)
          when '.gem'
            # Because we cd into the source dir, using ./ here avoids special casing gems in the Makefile
            return './'
          else
            fail "Don't know how to guess dirname for '#{@file}' with extension: '#{@extension}'. Please teach me."
          end
        end
      end
    end
  end
end
