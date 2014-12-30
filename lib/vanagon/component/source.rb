require 'vanagon/component/source/http'
require 'vanagon/component/source/git'

class Vanagon
  class Component
    class Source
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
                          Vanagon::Component::Source::Http.new(url, options[:sum], workdir)
                        when /^git/
                          Vanagon::Component::Source::Git.new(url, options[:ref], workdir)
                        else
                          fail "Don't know how to handle source of type '#{uri_scheme}' from url: '#{url}'"
                        end

        return local_source
      end
    end
  end
end
