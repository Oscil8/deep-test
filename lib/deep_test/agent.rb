module DeepTest
  class Agent
    include Demon
    attr_reader :number

    def initialize(number, central_command, listener)
      @number = number
      @central_command = central_command
      @listener = listener
    end

    def execute
      reseed_random_numbers
      reconnect_to_database

      @listener.starting(self)
      while work_unit = next_work_unit
        @listener.starting_work(self, work_unit)

        result = begin
                   work_unit.run
                 rescue Exception => error
                   Error.new(work_unit, error)
                 end

        @listener.finished_work(self, work_unit, result)
        @central_command.write_result result
        if ENV['DEEP_TEST_SHOW_WORKER_DOTS'] == 'yes'
          $stdout.print '.'
          $stdout.flush
        end
      end
    rescue CentralCommand::NoWorkUnitsRemainingError
      DeepTest.logger.debug { "Agent #{number}: no more work to do" }
    end

    private

    def next_work_unit
      @central_command.take_work
    rescue CentralCommand::NoWorkUnitsAvailableError
      sleep 0.02
      retry
    end

    def reconnect_to_database
      ActiveRecord::Base.connection.reconnect! if defined?(ActiveRecord::Base)
    end

    def reseed_random_numbers
      srand
    end


    class Error
      attr_accessor :work_unit, :error

      def initialize(work_unit, error)
        @work_unit, @error = work_unit, error
      end

      def _dump(limit)
        Marshal.dump([@work_unit, @error], limit)
      rescue
        Marshal.dump(["<< Undumpable >>", @error], limit)
      end

      def self._load(string)
        new *Marshal.load(string)
      end

      def ==(other)
        work_unit == other.work_unit &&
            error == other.error
      end

      def to_s
        "#{@work_unit}: #{@error}\n" + (@error.backtrace || []).join("\n")
      end
    end
  end
end
