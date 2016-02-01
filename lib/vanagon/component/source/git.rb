require 'vanagon/utilities'

class Vanagon
  class Component
    class Source
      class Git
        include Vanagon::Utilities
        attr_accessor :url, :ref, :workdir, :version, :cleanup

        # Constructor for the Git source type
        #
        # @param url [String] url of git repo to use as source
        # @param ref [String] ref to checkout from git repo
        # @param workdir [String] working directory to clone into
        def initialize(url, ref, workdir)
          unless ref
            fail "ref parameter is required for the git source"
          end
          @url = url
          @ref = ref
          @workdir = workdir
        end

        # Fetch the source. In this case, clone the repository into the workdir
        # and check out the ref. Also sets the version if there is a git tag as
        # a side effect.
        def fetch
          puts "Cloning ref '#{@ref}' from url '#{@url}'"
          Dir.chdir(@workdir) do
            git("clone #{@url}", true)
            Dir.chdir(dirname) do
              git("checkout #{@ref}", true)
              git("submodule update --init --recursive", true)
              @version = git_version
            end
          end
        end

        # Return the correct incantation to cleanup the source directory for a given source
        #
        # @return [String] command to cleanup the source
        def cleanup
          "rm -rf #{dirname}"
        end

        # There is no md5 to manually verify here, so it is a noop.
        def verify
          # nothing to do here, so just return
        end

        # The dirname to reference when building from the repo
        #
        # @return [String] the directory where the repo was cloned
        def dirname
          File.basename(@url).sub(/\.git/, '')
        end
      end
    end
  end
end
