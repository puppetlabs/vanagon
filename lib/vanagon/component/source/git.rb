require 'vanagon/utilities'
require 'vanagon/errors'
# This stupid library requires a capital 'E' in its name
# but it provides a wealth of useful constants
require 'English'
require 'fustigit'
require 'git/basic_submodules'
require 'logger'
require 'timeout'

class Vanagon
  class Component
    class Source
      class Git
        attr_accessor :url, :ref, :workdir, :clone_options
        attr_reader :version, :default_options, :repo

        class << self
          # Attempt to connect to whatever URL is provided and
          # return True or False depending on whether or not
          # `git` thinks it's a valid Git repo.
          #
          # @param url
          # @param timeout Time (in seconds) to wait before assuming the
          #        git command has failed. Useful in instances where a URL
          #        prompts for credentials despite not being a git remote
          # @return [Boolean] whether #url is a valid Git repo or not
          def valid_remote?(url, timeout = 0)
            Timeout.timeout(timeout) do
              !!::Git.ls_remote(url)
            end
          rescue ::Git::GitExecuteError
            false
          rescue Timeout::Error
            false
          end
        end

        # Default options used when cloning; this may expand
        # or change over time.
        def default_options # rubocop:disable Lint/DuplicateMethods
          @default_options ||= { ref: "HEAD" }
        end
        private :default_options

        # Constructor for the Git source type
        #
        # @param url [String] url of git repo to use as source
        # @param ref [String] ref to checkout from git repo
        # @param workdir [String] working directory to clone into
        def initialize(url, workdir:, **options)
          opts = default_options.merge(options.reject { |k, v| v.nil? })

          # Ensure that #url returns a URI object
          @url = URI.parse(url.to_s)
          @ref = opts[:ref]
          @workdir = File.realpath(workdir)
          @clone_options = opts[:clone_options] ||= {}

          # We can test for Repo existence without cloning
          raise Vanagon::InvalidRepo, "#{url} not a valid Git repo" unless valid_remote?
        end

        # Fetch the source. In this case, clone the repository into the workdir
        # and check out the ref. Also sets the version if there is a git tag as
        # a side effect.
        def fetch
          clone!
          checkout!
          version
          update_submodules
        end

        # Return the correct incantation to cleanup the source directory for a given source
        #
        # @return [String] command to cleanup the source
        def cleanup
          "rm -rf #{dirname}"
        end

        # There is no md5 to manually verify here, so this is a noop.
        def verify
          # nothing to do here, so just tell users that and return
          warn "Nothing to verify for '#{dirname}' (using Git reference '#{ref}')"
        end

        # The dirname to reference when building from the repo
        #
        # @return [String] the directory where the repo was cloned
        def dirname
          File.basename(url.path, ".git")
        end

        # Use `git describe` to lazy-load a version for this component
        def version # rubocop:disable Lint/DuplicateMethods
          @version ||= describe
        end

        # Perform a git clone of @url as a lazy-loaded
        # accessor for @clone
        def clone
          if @clone_options.empty?
            @clone ||= ::Git.clone(url, dirname, path: workdir)
          else
            @clone ||= ::Git.clone(url, dirname, path: workdir, **clone_options)
          end
        end

        # Attempt to connect to whatever URL is provided and
        # return True or False depending on whether or not
        # `git` thinks it's a valid Git repo.
        #
        # @return [Boolean] whether #url is a valid Git repo or not
        def valid_remote?
          self.class.valid_remote? url
        end
        private :valid_remote?

        # Provide a list of remote refs (branches and tags)
        def remote_refs
          (remote['tags'].keys + remote['branches'].keys).uniq
        end
        private :remote_refs

        # Provide a list of local refs (branches and tags)
        def refs
          (clone.tags.map(&:name) + clone.branches.map(&:name)).uniq
        end
        private :refs

        # Clone a remote repo, make noise about it, and fail entirely
        # if we're unable to retrieve the remote repo
        def clone!
          warn "Cloning Git repo '#{url}'"
          warn "Successfully cloned '#{dirname}'" if clone
        rescue ::Git::GitExecuteError
          raise Vanagon::InvalidRepo, "Unable to clone from '#{url}'"
        end
        private :clone!

        # Checkout desired ref/sha, make noise about it, and fail
        # entirely if we're unable to checkout that given ref/sha
        def checkout!
          warn "Checking out '#{ref}' from Git repo '#{dirname}'"
          clone.checkout(ref)
        rescue ::Git::GitExecuteError
          raise Vanagon::CheckoutFailed, "unable to checkout #{ref} from '#{url}'"
        end
        private :checkout!

        # Attempt to update submodules, and do not panic
        # if there are no submodules to initialize
        def update_submodules
          warn "Attempting to update submodules for repo '#{dirname}'"
          clone.update_submodules(init: true)
        end
        private :update_submodules

        # Determines a version for the given directory based on the git describe
        # for the repository
        #
        # @return [String] The version of the directory according to git describe
        def describe
          clone.describe(ref, tags: true)
        rescue ::Git::GitExecuteError
          warn "Directory '#{dirname}' cannot be versioned by Git. Maybe it hasn't been tagged yet?"
        end
        private :describe
      end
    end
  end

  class GitError < Error; end
  # Raised when a URI is not a valid Source Control repo
  class InvalidRepo < GitError; end
  # Raised when checking out a given ref from a Git Repo fails
  class CheckoutFailed < GitError; end
end
