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
    @component.configure << block.call
  end

  def build(&block)
    @component.build << block.call
  end

  def install(&block)
    @component.install << block.call
  end

  def environment(&block)
    @component.environment = block.call
  end

  def apply_patch(patch, flag = nil)
    @component.patches << patch
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

  # Utilities for handling service installation
  #
  #

  # install_service adds the commands to install the various files on
  # disk during the package build
  def install_service(service_file, default_file = nil, service_name = @component.name)
    case @component.platform.servicetype
    when "sysv"
      target_service_file = File.join(@component.platform.servicedir, service_name)
      target_default_file = File.join(@component.platform.defaultdir, service_name)
    when "systemd"
      target_service_file = File.join(@component.platform.servicedir, "#{service_name}.service")
      target_default_file = File.join(@component.platform.defaultdir, service_name)
    else
      fail "Don't know how to install the #{@component.platform.servicetype}. Please teach #install_service how to do this."
    end
    install_service_cmd = []
    install_service_cmd << "install -d '#{@component.platform.servicedir}'"
    install_service_cmd << "cp -p '#{service_file}' '#{target_service_file}'"
    @component.files << target_service_file

    if default_file
      install_service_cmd << "install -d '#{@component.platform.defaultdir}'"
      install_service_cmd << "cp -p '#{default_file}' '#{target_default_file}'"
      @component.files << target_default_file
    end

    # Actually append the cp calls to the @install instance var
    @component.install << install_service_cmd

    # Register the service for use in packaging
    @component.service = service_name
  end

  def install_file(source, target)
    @component.install << "install -d '#{File.dirname(target)}'"
    @component.install << "cp -p '#{source}' '#{target}'"
    @component.files << target
  end

  # link will add a command to the install to create a symlink from source to target
  def link(source, target)
    @component.install << "ln -s '#{source}' '#{target}'"
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
