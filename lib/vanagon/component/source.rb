require 'fustigit'
require 'vanagon/component/source/http'
require 'vanagon/component/source/git'
require 'vanagon/component/source/local'

class Vanagon
  class Component
    class Source
      SUPPORTED_PROTOCOLS = %w(file http https git).freeze
      @rewrite_rules = {}

      class << self
        attr_reader :rewrite_rules

        def register_rewrite_rule(protocol, rule)
          if rule.is_a?(String) || rule.is_a?(Proc)
            if SUPPORTED_PROTOCOLS.include?(protocol)
              @rewrite_rules[protocol] = rule
            else
              raise Vanagon::Error, "#{protocol} is not a supported protocol for rewriting"
            end
          else
            raise Vanagon::Error, "String or Proc is required as a rewrite_rule."
          end
        end

        def rewrite(url, protocol)
          # Vanagon did not originally distinguish between http and https
          # when looking up rewrite rules; this is no longer true, but it
          # means that we should try to preserve old, dumb behavior until
          # the rewrite engine is removed.
          return rewrite(url, "http") if protocol == "https"

          rule = @rewrite_rules[protocol]
          if rule
            if rule.is_a?(Proc)
              return proc_rewrite(rule, url)
            elsif rule.is_a?(String)
              return string_rewrite(rule, url)
            end
          end

          return url
        end

        def proc_rewrite(rule, url)
          if rule.arity == 1
            rule.call(url)
          else
            raise Vanagon::Error, "Unable to use provided rewrite rule. Expected Proc with one argument, Proc has #{rule.arity} arguments"
          end
        end

        def string_rewrite(rule, original_url)
          url = original_url.to_s
          target_match = url.match(/.*\/([^\/]*)$/)
          if target_match
            target = target_match[1]
            return File.join(rule, target)
          else
            raise Vanagon::Error, "Unable to apply url rewrite to '#{url}', expected to find at least one '/' in the url."
          end
        end

        def parse_and_rewrite(uri)
          url = URI.parse(uri)
          return url unless url.scheme
          rewrite(url.to_s, url.scheme)
        end

        # Basic factory to hand back the correct {Vanagon::Component::Source} subtype to the component
        #
        # @param url [String] URI of the source file (includes git@... style links)
        # @param options [Hash] hash of the options needed for the subtype
        # @param workdir [String] working directory to fetch the source into
        # @return [Vanagon::Component::Source] the correct subtype for the given source
        def source(uri, **options) # rubocop:disable Metrics/AbcSize
          # First we try git
          if Vanagon::Component::Source::Git.valid_remote?(parse_and_rewrite(uri))
            return Vanagon::Component::Source::Git.new parse_and_rewrite(uri),
              sum: options[:sum],
              ref: options[:ref],
              workdir: options[:workdir]
          end

          # Then we try HTTP
          if Vanagon::Component::Source::Http.valid_url?(parse_and_rewrite(uri))
            return Vanagon::Component::Source::Http.new parse_and_rewrite(uri),
              sum: options[:sum],
              workdir: options[:workdir],
              sum_type: options[:sum_type]
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
