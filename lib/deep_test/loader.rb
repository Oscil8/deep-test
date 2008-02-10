module DeepTest
  class Loader
    NO_FILTERS = Object.new.instance_eval do
      def filters; []; end;
      self
    end
    
    def self.run
      suite = Test::Unit::AutoRunner::COLLECTORS[:objectspace].call NO_FILTERS
      supervised_suite = DeepTest::SupervisedTestSuite.new(suite)
      require 'test/unit/ui/console/testrunner'
      result = Test::Unit::UI::Console::TestRunner.run(supervised_suite, Test::Unit::UI::NORMAL)
      return result.passed?
    end 
  end
end
