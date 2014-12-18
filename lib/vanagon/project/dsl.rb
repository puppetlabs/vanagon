require 'vanagon/project'
require 'vanagon/utilities'

class Vanagon
  class Project
    class DSL
      def initialize(name, platform)
        @name = name
        @project = Vanagon::Project.new(@name, platform)
      end

      def project(name, &block)
        block.call(self)
      end

      def _project
        @project
      end


      # Project attributes and DSL methods defined below
      #
      #
      # All purpose getter. This object, which is passed to the project block,
      # won't have easy access to the attributes of the @project, so we make a
      # getter for each attribute.
      #
      # We only magically handle get_ methods, any other methods just get the
      # standard method_missing treatment.
      #
      def method_missing(method, *args)
        attribute_match = method.to_s.match(/get_(.*)/)
        if attribute_match
          attribute = attribute_match.captures.first
          @project.send(attribute)
        elsif @project.settings.has_key?(method)
          return @project.settings[method]
        else
          super
        end
      end

      def setting(name, value)
        @project.settings[name] = value
      end

      def description(descr)
        @project.description = descr
      end

      def homepage(page)
        @project.homepage = page
      end

      def version(ver)
        @project.version = ver
      end


      def vendor(vend)
        @project.vendor = vend
      end

      def directory(dir)
        @project.directories << dir
      end

      def license(lic)
        @project.license = lic
      end

      def component(name)
        puts "Loading #{name}"
        component = Vanagon::Component.load_component(name, File.join(Vanagon::Driver.configdir, "components"), @project.settings, @project.platform)
        @project.components << component if component.url
      end
    end
  end
end
