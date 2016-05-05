require 'vanagon/component/source/http'
require 'vanagon/component/source/git'
require 'vanagon/component/source/local'

class Vanagon
  class Component
    class Source
      SUPPORTED_PROTOCOLS = ['file', 'http', 'git'].freeze
      @rewrite_rules = {}

      class << self
        attr_reader :rewrite_rules

        def register_rewrite_rule(protocol, rule)
          if rule.is_a?(String) or rule.is_a?(Proc)
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

        def string_rewrite(rule, url)
          target_match = url.match(/.*\/([^\/]*)$/)
          if target_match
            target = target_match[1]
            return File.join(rule, target)
          else
            raise Vanagon::Error, "Unable to apply url rewrite to '#{url}', expected to find at least one '/' in the url."
          end
        end

        # Basic factory to hand back the correct {Vanagon::Component::Source} subtype to the component
        #
        # @param url [String] URL to the source (includes git@... style links)
        # @param options [Hash] hash of the options needed for the subtype
        # @param workdir [String] working directory to fetch the source into
        # @return [Vanagon::Component::Source] the correct subtype for the given source
        def source(target_url, options, workdir)
          Vanagon::Component::Source::Git.new(
            url: target_url,
            ref: options[:ref],
            workdir: workdir,
            clone_depth: options[:clone_depth]
          )
        rescue Vanagon::InvalidRepo
          url = URI.parse(target_url)
          case url.scheme
          when "http"
            Vanagon::Component::Source::Http.new(
              url: rewrite(url, 'http'),
              sum: options[:sum],
              workdir: workdir
            )
          when "file"
            Vanagon::Component::Source::Local.new(
              url: rewrite(url, 'file'),
              workdir: workdir
            )
          else
            raise Vanagon::Error,
                  "Don't know how to handle source of type '#{url.scheme}' from url: '#{url}'"
          end
        end
      end
    end
  end
end
