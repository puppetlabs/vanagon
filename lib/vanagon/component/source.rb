require 'fustigit'
require 'vanagon/logger'
require 'vanagon/component/source/http'
require 'vanagon/component/source/git'
require 'vanagon/component/source/local'

class Vanagon
  class Component
    class Source
      SUPPORTED_PROTOCOLS = %w[file http https git].freeze

      class << self
        # Factory to hand back the correct {Vanagon::Component::Source} subtype to the component
        #
        # @param uri_instance [#to_s] URI of the source file (includes git@... style links)
        # @param options [Hash] hash of the options needed for the subtype
        # @param workdir [String] working directory to fetch the source into
        # @return [Vanagon::Component::Source] the correct subtype for the given source
        def source(uri_instance, **options) # rubocop:disable Metrics/AbcSize
          # Sometimes the uri comes in as a string, but sometimes it's already been
          # coerced into a URI object. The individual source providers will turn
          # the passed uri into a URI object if needed, but for this method we
          # want to work with the uri as a string.
          uri = uri_instance.to_s
          if uri.start_with?('git')
            source_type = :git
            # when using an http(s) source for a git repo, you should prefix the
            # url with `git:`, so something like `git:https://github.com/puppetlabs/vanagon`
            # strip the leading `git:` so we have a valid uri
            uri.sub!(/^git:http/, 'http')
          else
            source_type = determine_source_type(uri)
          end

          if source_type == :git
            return Vanagon::Component::Source::Git.new uri,
              sum: options[:sum],
              ref: options[:ref],
              workdir: options[:workdir],
              dirname: options[:dirname],
              clone_options: options[:clone_options]
          end

          if source_type == :http
            return Vanagon::Component::Source::Http.new uri,
              sum: options[:sum],
              workdir: options[:workdir],
              # Default sum_type is md5 if unspecified:
              sum_type: options[:sum_type] || "md5"
          end

          if source_type == :local
            return Vanagon::Component::Source::Local.new uri,
              workdir: options[:workdir]
          end

          # Unknown source type!
          raise Vanagon::Error,
            "Unknown file type: '#{uri}'; cannot continue"
        end

        def determine_source_type(uri)
          # if source_type isn't specified, let's try to figure out what we have
          # order of precedence for this is git, then http, then local

          # Add a 5 second timeout for the `git remote-ls` execution to deal with
          # URLs that incorrectly respond to git queries
          timeout = 5
          if Vanagon::Component::Source::Git.valid_remote?(uri, timeout)
            if uri =~ /^http/
              VanagonLogger.warn "Using http(s) URIs for github is deprecated. " \
                                 "Use `git:` URI scheme instead."
            end
            return :git
          end

          if Vanagon::Component::Source::Http.valid_url?(uri)
            return :http
          end

          if Vanagon::Component::Source::Local.valid_file?(uri)
            return :local
          end

          return :unknown
        end
      end
    end
  end
end
