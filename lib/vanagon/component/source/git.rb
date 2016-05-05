require 'vanagon/utilities'
require 'english'

class Vanagon
  class Component
    class Source
      class Git
        include Vanagon::Utilities
        attr_accessor :url, :ref, :workdir, :version, :cleanup, :clone_depth
        attr_reader :default_options

        def default_options
          @default_options ||= { clone_depth: 50 }
        end
        private :default_options

        # Constructor for the Git source type
        #
        # @param url [String] url of git repo to use as source
        # @param ref [String] ref to checkout from git repo
        # @param workdir [String] working directory to clone into
        def initialize(url:, ref:, workdir:, **options)
          opts = default_options.merge(options)

          @url = url
          @ref = ref
          @workdir = workdir
          @clone_depth = opts[:clone_depth]

          raise Vanagon::InvalidRepo, "#{url} not a valid git repo" unless valid_remote?
        end

        # Attempt to connect to whatever URL is provided and
        # return True or False depending on whether or not
        # `git` thinks it's a valid Git repo.
        #
        # @return [Boolean] whether #url is a valid Git repo or not
        def valid_remote?
          git "ls-remote '#{url}' > /dev/null 2>&1"
          $CHILD_STATUS.success?
        end

        # Perform a shallow git clone of @url
        #
        # @param depth [Fixnum] how deep git should attempt to clone.
        #   Be aware that this will retrieve this many levels deep across
        #   all references (branches and tags). This is often "cheaper"
        #   than a full clone, but runs the risk of a given #ref not being
        #   available within the resulting repo. See also #unshallow
        # @return [Boolean] success or failure of the `git clone` operation
        def shallow_clone(depth: clone_depth)
          git("clone --depth=#{depth} #{url}", true)
          $CHILD_STATUS.success?
        end

        # Perform a full git clone of @url
        #
        # @return [Boolean] success or failure of the `git clone` operation
        def full_clone
          git("clone #{url}", true)
          $CHILD_STATUS.success?
        end

        # Check out a given #ref inside a git repo
        #
        # @param raise [Boolean] (false) whether to raise on failure or simply
        #   return whatever status git returned and continue
        # @return [Boolean] success or failure of the `git clone` operation
        def checkout(raise: false)
          git("checkout '#{ref}'", raise)
          $CHILD_STATUS.success?
        end

        # Convert a shallow clone into a complete clone
        #
        # @return [Boolean] whether the clone conversion was successful
        def unshallow
          puts "Unshallowing #{dirname}..."
          git 'fetch --tags --unshallow > /dev/null 2>&1'
          $CHILD_STATUS.success?
        end

        # Fetch the source. In this case, clone the repository into the workdir
        # and check out the ref. Also sets the version if there is a git tag as
        # a side effect.
        def fetch
          puts "Cloning ref '#{ref}' from url '#{url}'"
          Dir.chdir(workdir) do
            shallow_clone
            Dir.chdir(dirname) do
              checkout || (unshallow && checkout(raise: true))
              git("submodule update --init --recursive", true)
              version = git_version
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
          File.basename(url.to_s, ".git")
        end
      end
    end
  end
end
