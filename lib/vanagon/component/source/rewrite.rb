require 'vanagon/component/source'
require 'vanagon/logger'

class Vanagon
  class Component
    class Source
      # This class has been extracted from Vanagon::Component::Source for the
      # sake of isolation and in service of its pending removal. Rewrite rules
      # should be considered deprecated. The removal will be carried out before
      # Vanagon 1.0.0 is released.
      class Rewrite
        @rewrite_rules = {}

        class << self
          attr_reader :rewrite_rules

          # @deprecated Please use the component DSL method #mirror(<URI>)
          #   instead. This method will be removed before Vanagon 1.0.0.
          def register_rewrite_rule(protocol, rule)
            VanagonLogger.info <<-HERE.undent
              rewrite rule support is deprecated and will be removed before Vanagon 1.0.0.
              Rewritten URLs will be automatically converted into mirror URLs for now but
              please use the component DSL method '#mirror url' to define new mirror URL
              sources for a given component.
            HERE
            if rule.is_a?(String) || rule.is_a?(Proc)
              if Vanagon::Component::Source::SUPPORTED_PROTOCOLS.include?(protocol)
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

          # @deprecated Please use the component DSL method #mirror(<URI>)
          #   instead. This method will be removed before Vanagon 1.0.0.
          def parse_and_rewrite(uri)
            return uri if rewrite_rules.empty?
            if !!uri.match(/^git:http/)
              VanagonLogger.info <<-HERE.undent
                `fustigit` parsing doesn't get along with how we specify the source
                type by prefixing `git`. As `rewrite_rules` are deprecated, we'll
                replace `git:http` with `http` in your uri. At some point this will
                break.
              HERE
              uri.sub!(/^git:http/, 'http')
            end
            url = URI.parse(uri)
            return url unless url.scheme
            rewrite(url.to_s, url.scheme)
          end
        end
      end
    end
  end
end
