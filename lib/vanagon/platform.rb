require 'vanagon/platform/deb'
require 'vanagon/platform/rpm'

class Vanagon::Platform
  attr_accessor :make, :servicedir, :defaultdir, :provisioning, :build_dependencies, :name, :vcloud_name, :cflags, :ldflags, :settings, :servicetype, :patch, :architecture

  def platform(name, &block)
    @name = name
    block.call(self, @settings)
  end

  # This allows instance variables to be accessed using the hash lookup syntax
  def [](key)
    if instance_variable_get("@#{key}")
      instance_variable_get("@#{key}")
    end
  end

  def provision_with(command)
    @provisioning = command
  end

  def install_build_dependencies_with(command)
    @build_dependencies = command
  end

  def package_name(project, platform = self)
    if is_deb?
      Vanagon::Platform::DEB.package_name(project, platform)
    elsif is_rpm?
      Vanagon::Platform::RPM.package_name(project, platform)
    end
  end

  def generate_package(project, platform = self)
    if is_deb?
      Vanagon::Platform::DEB.generate_package(project, platform)
    elsif is_rpm?
      Vanagon::Platform::RPM.generate_package(project, platform)
    end
  end

  def generate_packaging_artifacts(workdir, proj_name, binding)
    if is_deb?
      Vanagon::Platform::DEB.generate_packaging_artifacts(workdir, proj_name, binding)
    elsif is_rpm?
      Vanagon::Platform::RPM.generate_packaging_artifacts(workdir, proj_name, binding)
    else
      fail "Something went wrong. Please teach me how to #generate_packaging_artifacts for #{@name}"
    end
  end

  def architecture
    @architecture ||= @name.match(/^.*-.*-(.*)$/)[1]
  end

  def to_codename
    fail "#to_codename not implemented for non-debian platforms" unless is_deb?
    case @name
    when /^ubuntu-(.*)-.*$/
      case $1
      when "14.04"
        "trusty"
      when "12.04"
        "precise"
      when "10.04"
        "lucid"
      else
        "ubuntu"
      end
    when /^debian-(.*)-.*$/
      case $1
      when "6"
        "squeeze"
      when "7"
        "wheezy"
      when "8"
        "jessie"
      else
        "debian"
      end
    end
  end

  #
  # Utilities for platform matching
  #

  def is_deb?
    return !!@name.match(/^(debian|ubuntu|cumulus)-.*$/)
  end

  def is_rpm?
    return !!@name.match(/^(el|fedora|eos)-.*$/)
  end

  def is_el?
    return !!@name.match(/^el-.*$/)
  end

  def is_fedora?
    return !!@name.match(/^fedora-.*$/)
  end

  def is_aix?
    return !!@name.match(/^aix-.*$/)
  end
end
