require 'vanagon/utilities'
require 'vanagon/errors'
require 'english'

class Vanagon
  class Component
    class Source
      class Git
        attr_accessor :url, :ref, :workdir, :clone_depth
        attr_reader :default_options, :version

        GIT = Vanagon::Utilities.which('git')

        class << self
          # Simple wrapper around git command line executes the given commands and
          # returns the results. Required for Git.valid_remote? to function. Wrapped
          # by a private instance method of the same name, with the same options.
          #
          # @param command_string [String] The commands to be run
          # @param dir [String,Pathname] Directory to run the commands in
          # @param raisable [boolean] if this function should raise an error on a git failure
          # @param quiet [boolean] if this function should return output as a String or Boolean status
          # @return [String] the output of the command (if :quiet is false)
          # @return [Boolean] whether or not the command executed successfully (if :quiet is true)
          def git(command_string, dir: Dir.pwd, raisable: false, quiet: false)
            output = Dir.chdir(dir) { %x(#{GIT} #{command_string}) }

            if raisable && !$CHILD_STATUS.success?
              raise Vanagon::GitError, %('git #{command_string}' failed:\n#{output})
            end

            return $CHILD_STATUS.success? if quiet

            output
          end
          private :git

          # Attempt to connect to whatever URL is provided and
          # return True or False depending on whether or not
          # `git` thinks it's a valid Git repo.
          #
          # @return [Boolean] whether #url is a valid Git repo or not
          def valid_remote?(url)
            git("ls-remote '#{url}' > /dev/null 2>&1", quiet: true)
          end
        end

        def default_options
          @default_options ||= { ref: "refs/heads/master", clone_depth: nil }
        end
        private :default_options

        # Constructor for the Git source type
        #
        # @param url [String] url of git repo to use as source
        # @param ref [String] ref to checkout from git repo
        # @param workdir [String] working directory to clone into
        def initialize(url, workdir:, **options)
          opts = default_options.merge(options)
          puts opts.inspect
          @url = url
          @workdir = workdir
          @ref = opts[:ref]
          @ref_name, @ref_type, _ = @ref.split('/', 3).reverse
          @clone_depth = opts[:clone_depth]

          # We can test for Repo existence without cloning
          raise Vanagon::InvalidRepo, "#{url} not a valid git repo" unless valid_remote?
          # We can test for Ref existence in a repo without cloning
          raise Vanagon::UnknownRef, "#{ref} is not a valid ref in #{url}" unless valid_ref?
        end

        # Fetch the source. In this case, clone the repository into the workdir
        # and check out the ref. Also sets the version if there is a git tag as
        # a side effect.
        def fetch
          puts "Cloning ref '#{ref}' from url '#{url}'"
          Dir.chdir(workdir) do
            clone_depth ? shallow_clone : full_clone
            Dir.chdir(dirname) do
              checkout || (unshallow && checkout!)
              version
              update_submodules
            end
          end
        end

        # Return the correct incantation to cleanup the source directory for a given source
        #
        # @return [String] command to cleanup the source
        def cleanup
          "rm -rf #{dirname}"
        end

        # The dirname to reference when building from the repo
        #
        # @return [String] the directory where the repo was cloned
        def dirname
          File.basename(url.to_s, ".git")
        end

        def version
          @version ||= describe
        end

        # An instance wrapper around the private class method Git.git; takes the same
        # options as the class method.
        # @param command_string [String] The commands to be run
        # @param dir [String,Pathname] Directory to run the commands in
        # @param raisable [boolean] if this function should raise an error on a git failure
        # @param quiet [boolean] if this function should return output as a String or Boolean status
        # @return [String] the output of the command (if :quiet is false)
        # @return [Boolean] whether or not the command executed successfully (if :quiet is true)
        def git(command_string, **options)
          self.class.method(:git).call(command_string, options)
        end
        private :git

        def ref?
          @ref_type && @ref_name
        end
        private :ref?

        def valid_ref?
          return false unless ref?
          git "ls-remote --exit-code '#{url}' '#{ref}' > /dev/null 2>&1"
          $CHILD_STATUS.success?
        end
        private :valid_ref?

        # Attempt to connect to whatever URL is provided and
        # return True or False depending on whether or not
        # `git` thinks it's a valid Git repo.
        #
        # @return [Boolean] whether #url is a valid Git repo or not
        def valid_remote?
          self.class.valid_remote? url
        end
        private :valid_remote?

        def repo_path
          File.join(workdir, dirname)
        end
        private :repo_path

        def cloned?
          return false unless Dir.exist? repo_path
          git('rev-parse --git-dir > /dev/null 2>&1', dir: repo_path)
          $CHILD_STATUS.success?
        end
        private :cloned?

        # Perform a shallow git clone of @url
        #
        # @param depth [Fixnum] how deep git should attempt to clone.
        #   Be aware that this will retrieve this many levels deep across
        #   all references (branches and tags). This is often "cheaper"
        #   than a full clone, but runs the risk of a given #ref not being
        #   available within the resulting repo. See also #unshallow
        # @return [Boolean] success or failure of the `git clone` operation
        def shallow_clone(depth: clone_depth)
          git("clone --depth=#{depth} #{url}", raisable: true)
          $CHILD_STATUS.success?
        end
        private :shallow_clone

        # Perform a full git clone of @url
        #
        # @return [Boolean] success or failure of the `git clone` operation
        def full_clone
          git("clone #{url}", raisable: true)
          $CHILD_STATUS.success?
        end
        private :full_clone

        # Check out a given #ref inside a git repo
        #
        # @return [Boolean] success or failure of the `git clone` operation
        def checkout
          git("checkout '#{ref}' 2>/dev/null")
          $CHILD_STATUS.success?
        end
        private :checkout

        def checkout!
          raise Vanagon::CheckoutFailed, "unable to checkout #{ref} from #{url}" unless checkout
        end
        private :checkout!

        def update_submodules
          git("submodule update --init --recursive 2>/dev/null", raisable: true, quiet: true)
        end
        private :update_submodules

        # Convert a shallow clone into a complete clone
        #
        # @return [Boolean] whether the clone conversion was successful
        def unshallow
          puts "Unshallowing #{dirname}..."
          git('fetch --tags --unshallow > /dev/null 2>&1', dir: repo_path)
          $CHILD_STATUS.success?
        end
        private :unshallow

        # Determines a version for the given directory based on the git describe
        # for the repository
        #
        # @return [String] The version of the directory according to git describe
        def describe
          return nil unless cloned?

          output = git('describe --tags 2> /dev/null', dir: repo_path).chomp
          return output unless output.empty?

          warn "Directory '#{dirname}' cannot be versioned by git. Maybe it hasn't been tagged yet?"
        end
        private :describe
      end
    end
  end

  class GitError < Error; end
  # Raised when a URI is not a valid Source Control repo
  class InvalidRepo < GitError; end
  # Raised when a given ref doesn't exist in a Git Repo
  class UnknownRef < GitError; end
  # Raised when a given sha doesn't exist in a Git Repo
  class UnknownSha < GitError; end
  # Raised when checking out a given ref from a Git Repo fails
  class CheckoutFailed < GitError; end
end
