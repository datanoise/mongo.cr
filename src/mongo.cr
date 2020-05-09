require "log"
require "./bson"
require "./mongo/*"
require "./mongo/gridfs/*"

module Mongo
  Log = ::Log.for(self)

  def self.logger
    Log
  end

  protected def self.log(level, domain, msg)
    case level
    when LibMongoC::LogLevel::ERROR
      Log.error { msg }
    when LibMongoC::LogLevel::CRITICAL
      Log.fatal { msg }
    when LibMongoC::LogLevel::WARNING
      Log.warn { msg }
    when LibMongoC::LogLevel::INFO
      Log.info { msg }
    when LibMongoC::LogLevel::DEBUG
      Log.verbose { msg }
    when LibMongoC::LogLevel::TRACE
      Log.debug { msg }
    else
      Log.info { msg }
    end
  end

  LibMongoC.log_set_handler ->(level, domain, msg, user_data) {
    self.log(level, String.new(domain), String.new(msg))
  }, nil
  LibMongoC.mongo_init(nil)
  at_exit { LibMongoC.mongo_cleanup(nil) }
end
