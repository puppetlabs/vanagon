require 'vanagon/component/source/http'
require 'vanagon/component/source/git'
require 'uri'

class Vanagon
  class Component
    class Source
      def self.source(url, options, workdir)
        uri_scheme = URI.parse(url).scheme
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
