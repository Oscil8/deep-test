module DeepTest
  module Spec
    class WorkUnit
      def initialize(file, line)
        @file, @line = file, line
      end

      def run
        # Dup options here to avoid clobbering the reporter on someone
        # elses options reference (Such as ExampleGroupRunner)
        original_options, $rspec_options = $rspec_options, $rspec_options.dup
        rspec_options.reporter = ResultReporter.new(@file, @line)
        result = run_without_deadlock_protection
        result = run_without_deadlock_protection if result.failed_due_to_deadlock?
        result = result.deadlock_result if result.failed_due_to_deadlock?
        result
      ensure
        $rspec_options = original_options
      end

      protected

      def run_without_deadlock_protection
        output = capture_stdout do
          rspec_options.run_one_example(@file, @line)
        end
        rspec_options.reporter.result(output)
      end

      class ResultReporter
        attr_reader :result
        def initialize(file,line)
          @file, @line = file, line
        end

        def add_example_group(example_group); end
        def dump; end
        def end; end
        def example_started(name); end

        def example_finished(example, error)
          @example, @error = example, error
        end

        def result(output)
          Spec::WorkResult.new(@file, @line, @example.description, @error, output)
        end

        def start(example); end
      end
    end
  end
end
