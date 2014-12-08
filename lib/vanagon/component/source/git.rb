require 'vanagon/utilities'

class Vanagon
  class Component
    class Source
      class Git
        include Vanagon::Utilities
        attr_accessor :url, :ref, :workdir, :version

        def initialize(url, ref, workdir)
          @url = url
          @ref = ref
          @workdir = workdir
          @git = ex('which git').chomp
        end

        def fetch
          Dir.chdir(@workdir) do
            ex("#{@git} clone '#{@url}'")
            Dir.chdir(dirname) do
              ex("#{@git} checkout '#{@ref}'")
              @version = ex("#{@git} describe --tags").chomp
            end
          end
        end

        def verify
          # nothing to do here, so just return
        end

        def dirname
          File.basename(@url).sub(/\.git/, '')
        end

        def extract
          # Nothing to extract
          return nil
        end
      end
    end
  end
end
