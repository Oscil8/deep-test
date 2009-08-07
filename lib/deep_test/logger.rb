module DeepTest
  class Logger < ::Logger
    def initialize(*args)
      super
      hostname = Socket.gethostname
      self.formatter = proc { |severity, time, progname, msg| "[DeepTest@#{hostname}] #{time.strftime "%F %T"} #{msg}\n" }
      self.level = configured_log_level
    end

    def io_stream
      @logdev.dev
    end

    def configured_log_level
      if ENV['DEEP_TEST_LOG_LEVEL']
        Logger.const_get(ENV['DEEP_TEST_LOG_LEVEL'].upcase)
      else
        Logger::INFO
      end
    end

    Severity.constants.each do |severity|
      eval <<-end_src
        def #{severity.downcase}
          super
        rescue Exception => e
          super "\#{e.class}: \#{e} occurred logging on \#{caller[0]}", &nil
        end
      end_src
    end
  end
end
