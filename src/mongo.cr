require "log"
require "./bson"
require "./mongo/*"
require "./mongo/gridfs/*"

module Mongo
  @@logger = ::Log.for("db")

  def self.logger
    @@logger
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.driver_version
    String.new LibMongoC.mongo_version(nil)
  end

  def self.ssl_opt_get_default
    ssl_defaults = LibMongoC.ssl_opt_get_default(nil)
    cpy = LibMongoC::SSLOpt.new
    ssl_ptr = pointerof(cpy)
    ssl_defaults.copy_to(ssl_ptr,1)
    cpy
  end

  protected def self.log(level, domain, msg)
      case level
      when LibMongoC::LogLevel::ERROR
        logger.try &.error {msg}
      when LibMongoC::LogLevel::CRITICAL
        logger.try &.fatal {msg}
      when LibMongoC::LogLevel::WARNING
        logger.try &.warn {msg}
      when LibMongoC::LogLevel::INFO
        logger.try &.info {msg}
      when LibMongoC::LogLevel::DEBUG
        logger.try &.debug {msg}
      when LibMongoC::LogLevel::TRACE
        logger.try &.trace {msg}
      else
        logger.try &.notice {msg}
      end
  end

  LibMongoC.log_set_handler ->(level, domain, msg, user_data) {
    self.log(level, String.new(domain), String.new(msg))
  }, nil
  LibMongoC.mongo_init(nil)
  at_exit { LibMongoC.mongo_cleanup(nil) }
end
