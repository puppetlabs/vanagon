require 'logger'

class VanagonLogger < ::Logger
  def self.logger
    @@logger ||= VanagonLogger.new
  end

  def self.debug_logger
    @@debug_logger ||= VanagonLogger.new(STDERR)
  end

  def self.info(msg)
    VanagonLogger.debug_logger.info msg
  end

  def self.warn(msg)
    VanagonLogger.logger.warn msg
  end

  def self.error(msg)
    VanagonLogger.logger.error msg
  end

  def initialize(output = STDOUT)
    super(output)
    self.level = ::Logger::INFO
    self.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end
  end
end
