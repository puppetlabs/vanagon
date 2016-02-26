require 'pathname'

class Vanagon
  class Windows
    class Pathname < Vanagon::Common::Pathname

      # @!attribute wix_id
      #   @return [String] Returns the wix_id representing the id representing
      #   a file or directory in wix
      attr_accessor :wix_id

      # Extension of the VANAGON::COMMON::PATHNAME class specifially for windows
      # @param [String, Integer] mode the UNIX Octal permission string to use when this file is archived
      # @param [String, Integer] owner the username or UID to use when this file is archived
      # @param [String, Integer] group the groupname or GID to use when this file is archived
      # @param [Boolean] options => {config} mark this file as a configuration file, stored as private state
      #   and exposed through the {#configfile?} method.
      # @param [string] options => {id} the id to pass to wix objects during directory generation
      # @return [Vanagon::Common::Pathname] Returns a new Pathname instance.
      def initialize(path, mode: nil, owner: nil, group: nil, config: false, wix_id: nil)
        super(path, mode: nil, owner: nil, group: nil, config: false)
        # When the wix actually gets generated the "id" field in the wix elements
        # will already default to whatever the name field indicates. this is only
        # if you want to override that
        if wix_id
          @wix_id ||= wix_id
        end
      end

    end
  end
end
