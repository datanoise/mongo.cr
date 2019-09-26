require "logger"
require "./bson"
require "./mongo/*"
require "./mongo/gridfs/*"

module Mongo
  @@logger = Logger.new(STDIN)

  def self.logger
    @@logger
  end

  def self.logger=(logger)
    @@logger = logger
  end

  protected def self.log(level, domain, msg)
    log_level =
      case level
      when LibMongoC::LogLevel::ERROR
        Logger::Severity::ERROR
      when LibMongoC::LogLevel::CRITICAL
        Logger::Severity::FATAL
      when LibMongoC::LogLevel::WARNING
        Logger::Severity::WARN
      when LibMongoC::LogLevel::INFO
        Logger::Severity::INFO
      when LibMongoC::LogLevel::DEBUG
        Logger::Severity::DEBUG
      when LibMongoC::LogLevel::TRACE
        Logger::Severity::DEBUG
      else
        Logger::Severity::INFO
      end
    logger.try &.log(log_level, msg, domain)
  end

  LibMongoC.log_set_handler ->(level, domain, msg, user_data) {
    self.log(level, String.new(domain), String.new(msg))
  }, nil
  LibMongoC.mongo_init(nil)
  at_exit { LibMongoC.mongo_cleanup(nil) }
end
