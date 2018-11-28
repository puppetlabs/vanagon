require 'vanagon/errors'

class Vanagon
  class Patch
    # @!attribute [r] origin_path
    #   @return [String] The path to the patch before assembly
    attr_reader :origin_path

    # @!attribute [r] namespace
    #   @return [String] The namespace for the patch
    attr_reader :namespace

    # @!attribute [r] assembly_path
    #   @return [String] The path to the patch inside the assembly
    attr_reader :assembly_path

    # @!attribute [r] destination
    #   @return [String] The working directory where this patch will be applied.
    #     Only used for post-installation patches.
    attr_reader :destination

    # @!attribute [r] strip
    #   @return [Integer] the number of path components to strip from the patch path
    attr_reader :strip

    # @!attribute [r] fuzz
    #   @return [Integer] The fuzz factor for applying the patch
    attr_reader :fuzz

    # @!attribute [r] after
    #   @return [String] What step should this patch be applied to, one of ["unpack", "install"]
    attr_reader :after

    def initialize(origin_path, component, options) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
      valid_keys = %i[namespace destination strip fuzz after]
      bad_keys = options.each_key.reject { |k| valid_keys.include? k }

      unless bad_keys.empty?
        raise Vanagon::Error, "Bad options in patch initialization: #{bad_keys}."
      end

      @origin_path = origin_path
      @namespace = options[:namespace] || component.name
      @assembly_path = "patches/#{@namespace}/#{File.basename(@origin_path)}"
      @strip = options[:strip] || 1
      @fuzz = options[:fuzz] || 0
      @after = options[:after] || 'unpack'
      unless ['unpack', 'install'].include?(@after)
        raise Vanagon::Error, 'Only "unpack" or "install" permitted for "after" option.'
      end
      @destination = options[:destination] || component.dirname
    end

    def cmd(platform)
      return "#{platform.patch} --strip=#{@strip} --fuzz=#{@fuzz} --ignore-whitespace --no-backup-if-mismatch < $(workdir)/#{@assembly_path}"
    end
  end
end
