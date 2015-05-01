require 'vanagon/component/source/http'
require 'vanagon/component/source/git'

class Vanagon
  class Component
    class Source
      SUPPORTED_PROTOCOLS = ['file', 'http', 'git']
      @@rewrite_rule = {}

      def self.register_rewrite_rule(protocol, rule)
        if rule.is_a?(String) or rule.is_a?(Proc)
          if SUPPORTED_PROTOCOLS.include?(protocol)
            @@rewrite_rule[protocol] = rule
          else
            raise Vanagon::Error.new("#{protocol} is not a supported protocol for rewriting")
          end
        else
          raise Vanagon::Error.new("String or Proc is required as a rewrite_rule. ")
        end
      end

      def self.rewrite(url, protocol)
        rule = @@rewrite_rule[protocol]
        if rule
          if rule.is_a?(Proc) and rule.arity == 1
            return rule.call(url)
          elsif rule.is_a?(String)
            target_match = url.match(/.*\/([^\/]*)$/)
            if target_match
              target = target_match[1]
              return File.join(rule, target)
            else
              raise Vanagon::Error.new("Unable to apply url rewrite to '#{url}', expected to find at least one '/' in the url.")
            end
          else
          end
        else
          return url
        end
      end

      # Basic factory to hand back the correct {Vanagon::Component::Source} subtype to the component
      #
      # @param url [String] URL to the source (includes git@... style links)
      # @param options [Hash] hash of the options needed for the subtype
      # @param workdir [String] working directory to fetch the source into
      # @return [Vanagon::Component::Source] the correct subtype for the given source
      def self.source(url, options, workdir)
        url_match = url.match(/^(.*)(@|:\/\/)(.*)$/)
        uri_scheme = url_match[1] if url_match
        local_source =  case uri_scheme
                        when /^http/
                          Vanagon::Component::Source::Http.new(self.rewrite(url, 'http'), options[:sum], workdir)
                        when /^file/
                          Vanagon::Component::Source::Http.new(self.rewrite(url, 'file'), options[:sum], workdir)
                        when /^git/
                          Vanagon::Component::Source::Git.new(self.rewrite(url, 'git'), options[:ref], workdir)
                        else
                          fail "Don't know how to handle source of type '#{uri_scheme}' from url: '#{url}'"
                        end

        return local_source
      end
    end
  end
end
