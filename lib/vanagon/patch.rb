require 'vanagon/errors'

class Vanagon
  class Patch
    # @!attribute [r] path
    #   @return [String] The path to the patch
    attr_reader :path

    # @!attribute [r] strip
    #   @return [Integer] the number of path components to strip from the patch path
    attr_reader :strip

    # @!attribute [r] fuzz
    #   @return [Integer] The fuzz factor for applying the patch
    attr_reader :fuzz

    # @!attribute [r] after
    #   @return [String] What step should this patch be applied to, one of ["unpack", "install"]
    attr_reader :after

    # @!attribute [r] destination
    #   @return [String] The working directory where this patch will be applied. Only used for post-installation patches.
    attr_reader :destination

    def initialize(path, strip, fuzz, after, destination)
      raise Vanagon::Error, "We can only apply patches after the source is unpacked or after installation" unless ['unpack', 'install'].include?(after)
      @path = path
      @strip = strip
      @fuzz = fuzz
      @after = after
      @destination = destination
    end

    def cmd(platform)
      "#{platform.patch} --strip=#{@strip} --fuzz=#{@fuzz} --ignore-whitespace < $(workdir)/patches/#{File.basename(@path)}"
    end
  end
end
