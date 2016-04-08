require 'vanagon/utilities'
require 'net/http'
require 'uri'

class Vanagon
  class Component
    class Source
      class Local
        include Vanagon::Utilities
        attr_accessor :url, :file, :extension, :workdir, :cleanup

        # Extensions for files we intend to unpack during the build
        ARCHIVE_EXTENSIONS = '.tar.gz', '.tgz', '.zip'

        # Constructor for the File source type
        #
        # @param url [String] url of the http source to fetch
        # @param workdir [String] working directory to download into
        def initialize(url, workdir)
          @url = url
          @workdir = workdir
        end

        # Download the source from the url specified. Sets the full path to the
        # file as @file and the @extension for the file as a side effect.
        def fetch
          @file = download
          @extension = get_extension
        end

        # Local files need no checksum so this is a noop
        def verify
          # nothing to do here, so just return
        end

        # Moves file from source to workdir
        #
        # @raise [RuntimeError, Vanagon::Error] an exception is raised if the URI scheme cannot be handled
        def download
          uri = URI.parse(@url)
          target_file = File.basename(uri.path)
          puts "Moving file '#{target_file}' to workdir"

          uri = @url.match(/^file:\/\/(.*)$/)
          if uri
            source_file = uri[1]
            target_file = File.basename(source_file)
            FileUtils.cp(source_file, File.join(@workdir, target_file))
          else
            raise Vanagon::Error, "Unable to parse '#{@url}' for local file path."
          end

          target_file

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