require 'rubygems'
require 'test/unit'
require 'dust'
require 'mocha'
require 'set'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + "/../infrastructure/timewarp/lib")
require "deep_test"
require 'timewarp'

require File.dirname(__FILE__) + "/fake_deadlock_error"
require File.dirname(__FILE__) + "/drb_test_help"
require File.dirname(__FILE__) + "/fake_central_command"
require File.dirname(__FILE__) + "/test_factory"
require File.dirname(__FILE__) + "/test_logger"
require File.dirname(__FILE__) + "/../spec/thread_agent"

class SomeCustomException < RuntimeError
end

class Test::Unit::TestCase
  class <<self
    def dynamic_teardowns
      @dynamic_teardowns ||= []
    end

    def on_teardown(&block)
      dynamic_teardowns << block
    end

    def run_dynamic_teardowns
      while td = dynamic_teardowns.shift
        td.call rescue nil
      end
    end
  end

  def setup
    @old_logger = DeepTest.logger
    DeepTest.logger = TestLogger.new
  end

  def teardown
    DeepTest.logger = @old_logger if @old_logger
    Test::Unit::TestCase.run_dynamic_teardowns
  end

  def at(time, &block)
    Timewarp.freeze(time, &block)
  end
end
