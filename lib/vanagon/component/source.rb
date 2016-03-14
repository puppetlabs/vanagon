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
            raise Vanagon::Error, "#{protocol} is not a supported protocol for rewriting"
          end
        else
          raise Vanagon::Error, "String or Proc is required as a rewrite_rule."
        end
      end

      def self.rewrite(url, protocol)
        rule = @@rewrite_rule[protocol]

        if rule
          if rule.is_a?(Proc)
            return proc_rewrite(rule, url)
          elsif rule.is_a?(String)
            return string_rewrite(rule, url)
          end
        end

        return url
      end

      def self.proc_rewrite(rule, url)
        if rule.arity == 1
          rule.call(url)
        else
          raise Vanagon::Error, "Unable to use provided rewrite rule. Expected Proc with one argument, Proc has #{rule.arity} arguments"
        end
      end

      def self.string_rewrite(rule, url)
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
      def self.source(url, options, workdir)
        url_match = url.match(/^(.*)(@|:\/\/)(.*)$/)
        uri_scheme = url_match[1] if url_match
        local_source =  case uri_scheme
                        when /^http/
                          Vanagon::Component::Source::Http.new(self.rewrite(url, 'http'), options[:sum], workdir, options[:upstream_url])
                        when /^file/
                          Vanagon::Component::Source::Http.new(self.rewrite(url, 'file'), options[:sum], workdir, options[:upstream_url])
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
