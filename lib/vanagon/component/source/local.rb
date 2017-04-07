require 'vanagon/utilities'

class Vanagon
  class Component
    class Source
      class Local
        attr_accessor :url, :file, :extension, :workdir, :cleanup

        # Extensions for files we intend to unpack during the build
        ARCHIVE_EXTENSIONS = {
          "7z" => %w[.7z],
          "bzip2" => %w[.bz2 .bz],
          "cpio" => %w[.cpio],
          "gzip" => %w[.gz .z],
          "rar" => %w[.rar],
          "tar" => %w[.tar],
          "tbz2" => %w[.tar.bz2 .tbz2 .tbz],
          "tgz" => %w[.tar.gz .tgz],
          "txz" => %w[.tar.xz .txz],
          "xz" => %w[.xz],
          "zip" => %w[.zip],
        }.freeze

        class << self
          def valid_file?(target_file)
            File.exist?(mangle(target_file.to_s))
          end

          # If a scheme is specified as "file://", this will return
          # strip off the scheme and delimiters -- we need to do this because
          # once upon a time we allowed specifying files with no strong
          # specifications for where they should be located.
          def mangle(path)
            path.gsub(%r{^file://}, '')
          end

          def archive_extensions
            ARCHIVE_EXTENSIONS.values.flatten
          end
        end


        # Constructor for the File source type
        #
        # @param path [String] path of the local file to copy
        # @param workdir [String] working directory to copy <path> to
        def initialize(path, workdir:, **options)
          @url = ::Pathname.new(mangle(path))
          @workdir = ::Pathname.new(workdir)
        end

        # Local files need no checksum so this is a noop
        def verify
          # nothing to do here, so just return
        end

        # Moves file from source to workdir
        #
        # @raise [RuntimeError, Vanagon::Error] an exception is raised if the URI scheme cannot be handled
        def copy
          $stderr.puts "Copying file '#{url.basename}' to workdir"

          FileUtils.cp_r(url, file)
        end
        alias_method :fetch, :copy

        def file
          @file ||= workdir + File.basename(url)
        end

        def extension
          @extension ||= extname
        end

        # Gets the command to extract the archive given if needed (uses @extension)
        #
        # @param tar [String] the tar command to use
        # @return [String, nil] command to extract the source
        # @raise [RuntimeError] an exception is raised if there is no known extraction method for @extension
        def extract(tar = "tar") # rubocop:disable Metrics/AbcSize
          # Extension does not appear to be an archive, so "extract" is a no-op
          return ': nothing to extract' unless archive_extensions.include?(extension)

          case decompressor
          when "7z"
            %(7z x "#{file}")
          when "bzip2"
            %(bunzip2 "#{file}")
          when "cpio"
            %(
              mkdir "#{file.basename}" &&
              pushd "#{file.basename}" 2>&1 > /dev/null &&
              cpio -idv < "#{file}" &&
              popd 2>&1 > /dev/null
            ).undent
          when "gzip"
            %(gunzip "#{file}")
          when "rar"
            %(unrar x "#{file}")
          when "tar"
            %(#{tar} xf "#{file}")
          when "tbz2"
            %(bunzip2 -c "#{file}" | #{tar} xf -)
          when "tgz"
            %(gunzip -c "#{file}" | #{tar} xf -)
          when "txz"
            %(unxz -d "#{file}" | #{tar} xvf -)
          when "xz"
            %(unxz "#{file}")
          when "zip"
            "unzip -d '#{File.basename(file, '.zip')}' '#{file}' || 7za x -r -tzip -o'#{File.basename(file, '.zip')}' '#{file}'"
          else
            raise Vanagon::Error, "Don't know how to decompress #{extension} archives"
          end
        end

        # Return the correct incantation to cleanup the source archive and source directory for a given source
        #
        # @return [String] command to cleanup the source
        # @raise [RuntimeError] an exception is raised if there is no known extraction method for @extension
        def cleanup
          archive? ? "rm #{file}; rm -r #{dirname}" : "rm #{file}"
        end

        # Returns the extension for @file
        #
        # @return [String] the extension of @file
        def extname
          extension_match = file.to_s.match %r{#{Regexp.union(archive_extensions)}\Z}
          return extension_match.to_s if extension_match
          File.extname(file)
        end

        def archive_extensions
          self.class.archive_extensions
        end

        def archive?
          archive_extensions.include?(extension)
        end

        def decompressor
          @decompressor ||= ARCHIVE_EXTENSIONS.select { |k, v| v.include? extension }.keys.first
        end

        # The dirname to reference when building from the source
        #
        # @return [String] the directory that should be traversed into to build this source
        # @raise [RuntimeError] if the @extension for the @file isn't currently handled by the method
        def dirname
          # We are not treating file as a Pathname since other sources can inherit from this class
          # which could cause file to be a URI instead of a string.
          if archive? || File.directory?(file)
            File.basename(file, extension)
          else
            './'
          end
        end

        # Wrapper around the class method '.mangle'
        def mangle(path)
          self.class.mangle(path)
        end
      end
    end
  end
end
