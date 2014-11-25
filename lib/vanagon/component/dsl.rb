require 'vanagon/component'

class Vanagon::Component::DSL
  def initialize(name, settings, platform)
    @name = name
    @component = Vanagon::Component.new(@name, settings, platform)
  end

  def component(name, &block)
    block.call(self, @component.settings, @component.platform)
  end

  def _component
    @component
  end

  # All purpose getter. This object, which is passed to the component block,
  # won't have easy access to the attributes of the @component, so we make a
  # getter for each attribute.
  #
  # We only magically handle get_ methods, any other methods just get the
  # standard method_missing treatment.
  #
  def method_missing(method, *args)
    attribute_match = method.to_s.match(/get_(.*)/)
    if attribute_match
      attribute = attribute_match.captures.first
    else
      super
    end

    @component.send(attribute)
  end

  # Component attributes and DSL methods defined below
  #
  #
  def configure(&block)
    @component.configure = block.call
  end

  def build(&block)
    @component.build = block.call
  end

  def install(&block)
    @component.install = block.call
  end

  def environment(&block)
    @component.environment = block.call
  end

  def apply_patch(patch, flag = nil)
    @component.patches << patch
  end

  def add_service_file(file)
    @component.service_files << file
  end

  # build_requires adds a requirements to the list of build time dependencies
  # that will need to be fetched from an external source before this component
  # can be built. build_requires can also be satisfied by other components in
  # the same project.
  def build_requires(build_requirement)
    @component.build_requires << build_requirement
  end

  # requires adds a requirement to the list of runtime requirements for the
  # component
  def requires(requirement)
    @component.requires << requirement
  end

  def version(ver)
    @component.version = ver
  end

  def url(the_url)
    @component.url = the_url
  end

  def md5sum(md5)
    @component.md5sum = md5
  end
end
