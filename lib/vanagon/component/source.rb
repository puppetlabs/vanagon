require 'fustigit'
require 'vanagon/component/source/http'
require 'vanagon/component/source/git'
require 'vanagon/component/source/local'

class Vanagon
  class Component
    class Source
      SUPPORTED_PROTOCOLS = %w[file http https git].freeze

      class << self
        # Basic factory to hand back the correct {Vanagon::Component::Source} subtype to the component
        #
        # @param url [String] URI of the source file (includes git@... style links)
        # @param options [Hash] hash of the options needed for the subtype
        # @param workdir [String] working directory to fetch the source into
        # @return [Vanagon::Component::Source] the correct subtype for the given source
        def source(uri, **options)
          # First we try git
          if Vanagon::Component::Source::Git.valid_remote?(uri)
            return Vanagon::Component::Source::Git.new uri,
              sum: options[:sum],
              ref: options[:ref],
              workdir: options[:workdir]
          end

          # Then we try HTTP
          if Vanagon::Component::Source::Http.valid_url?(uri)
            return Vanagon::Component::Source::Http.new uri,
              sum: options[:sum],
              workdir: options[:workdir],
              # Default sum_type is md5 if unspecified:
              sum_type: options[:sum_type] || "md5"
          end

          # Then we try local
          if Vanagon::Component::Source::Local.valid_file?(uri)
            return Vanagon::Component::Source::Local.new uri,
              workdir: options[:workdir]
          end

          # Failing all of that, we give up
          raise Vanagon::Error,
            "Unknown file type: '#{uri}'; cannot continue"
        end
      end
    end
  end
end
