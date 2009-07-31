module DeepTest
  module Distributed
    class RemoteDeployment
      def initialize(options, landing_fleet, failover_deployment)
        @failover_deployment = failover_deployment
        @options = options
        @landing_fleet = landing_fleet
      end

      def load_files(filelist)
        # load one file before calling listeners to make sure environment has
        # been initialized as expected
        #
        load filelist.first
        @options.new_listener_list.before_sync

        t = Thread.new do
          @landing_fleet.push_code(@options)
          @landing_fleet.establish_beachhead(@options)
          @landing_fleet.load_files filelist
        end

        filelist[1..-1].each {|f| load f}

        begin
          t.join
        rescue => e
          # The failover here doesn't invoke load_files on the failover_deployment
          # because it will be a LocalDeployment, which forks from the current 
          # process.  The fact that we depend in this here is damp...
          #
          fail_over("load_files", e)
        end
      end

      def deploy_agents
        DeepTest.logger.debug { "RemoteDeployment deploying agents with #{@landing_fleet}" }
        @landing_fleet.deploy_agents
      rescue => e
        raise if failed_over?
        fail_over("deploy_agents", e)
        retry
      end

      def fail_over(method, exception)
        DeepTest.logger.debug { "RemoteDeployment failing over on #{method}." }
        @options.ui_instance.distributed_failover_to_local(method, exception)
        @landing_fleet = @failover_deployment
      end

      def failed_over?
        @landing_fleet == @failover_deployment
      end
    end
  end
end
