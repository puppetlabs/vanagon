require 'vanagon/utilities'
require 'vanagon/errors'
# This stupid library requires a capital 'E' in its name
# but it provides a wealth of useful constants
require 'English'
require 'fustigit'
require 'git/unshallow_repositories'
require 'git/basic_submodules'
require 'logger'

class Vanagon
  class Component
    class Source
      class Git
        attr_accessor :url, :ref, :workdir, :depth
        attr_reader :version, :default_options, :repo

        class << self
          # Attempt to connect to whatever URL is provided and
          # return True or False depending on whether or not
          # `git` thinks it's a valid Git repo.
          #
          # @return [Boolean] whether #url is a valid Git repo or not
          def valid_remote?(url)
            !!::Git.ls_remote(url)
          rescue ::Git::GitExecuteError
            false
          end
        end

        def default_options
          @default_options ||= { ref: "refs/heads/master", depth: nil }
        end
        # private :default_options

        # Constructor for the Git source type
        #
        # @param url [String] url of git repo to use as source
        # @param ref [String] ref to checkout from git repo
        # @param workdir [String] working directory to clone into
        def initialize(url, workdir:, **options)
          opts = default_options.merge(options)

          # Ensure that #url returns a URI object
          @url = URI.parse(url.to_s)
          @ref = opts[:ref]
          @workdir = workdir
          @depth = opts[:depth]
          @ref_name, @ref_type, _ = @ref.split('/', 3).reverse

          # We can test for Repo existence without cloning
          raise Vanagon::InvalidRepo, "#{url} not a valid git repo" unless valid_remote?
        end

        # Fetch the source. In this case, clone the repository into the workdir
        # and check out the ref. Also sets the version if there is a git tag as
        # a side effect.
        def fetch
          clone
          checkout || (unshallow && checkout!)
          version
          update_submodules
        end

        def ref
          @ref_name || @ref
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
          puts "Nothing to verify for Git sources"
        end

        # The dirname to reference when building from the repo
        #
        # @return [String] the directory where the repo was cloned
        def dirname
          File.basename(url.path, ".git")
        end

        def version
          @version ||= describe
        end

        # Attempt to connect to whatever URL is provided and
        # return True or False depending on whether or not
        # `git` thinks it's a valid Git repo.
        #
        # @return [Boolean] whether #url is a valid Git repo or not
        def valid_remote?
          self.class.valid_remote? url
        end
        # private :valid_remote?

        def valid_ref?
          refs.include? ref
        end
        # private :valid_ref?

        def remote_refs
          (remote['tags'].keys + remote['branches'].keys).uniq
        end

        def refs
          (clone.tags.map(&:name) + clone.branches.map(&:name)).uniq
        end
        # private :refs

        # Perform a git clone of @url
        def clone
          @clone ||= ::Git.clone(url, dirname, path: workdir, depth: depth)
        end
        # private :clone

        def checkout
          return false unless valid_ref?
          clone.checkout(ref)
        end
        # private :checkout

        def checkout!
          raise Vanagon::CheckoutFailed, "unable to checkout #{ref} from #{url}" unless checkout
        end
        # private :checkout!

        def update_submodules
          clone.update_submodules(init: true)
        end
        # private :update_submodules

        # Convert a shallow clone into a complete clone
        #
        # @return [Boolean] whether the clone conversion was successful
        def unshallow
          clone.fetch(clone.remote, unshallow: true, tags: true)
        end
        # private :unshallow

        # Determines a version for the given directory based on the git describe
        # for the repository
        #
        # @return [String] The version of the directory according to git describe
        def describe
          clone.describe(ref, tags: true)
        rescue ::Git::GitExecuteError
          warn "Directory '#{dirname}' cannot be versioned by git. Maybe it hasn't been tagged yet?"
        end
        # private :describe
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
