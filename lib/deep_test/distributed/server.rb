module DeepTest
  module Distributed
    class Server
      def initialize(config)
        @config = config
      end

      def sync(options)
        DeepTest.logger.debug { "mirror sync for #{options.origin_hostname}" }
        path = options.mirror_path(@config[:work_dir])
        DeepTest.logger.debug { "Syncing #{options.sync_options[:source]} to #{path}" }
        RSync.push(@config[:address], options, path)
      end

      def spawn_worker_server(options)
        output  = `#{ssh_command(options)} '#{spawn_command(options)}'`
        output.each do |line|
          if line =~ /RemoteWorkerServer url: (.*)/
            return DRb::DRbObject.new_with_uri($1)
          end
        end
      end

      def ssh_command(options)
        username_option = if options.sync_options[:username]
                            " -l #{options.sync_options[:username]}"
                          else
                            ""
                          end

        "ssh -4 #{@config[:address]}#{username_option}"
      end

      def spawn_command(options)
        "#{ShellEnvironment.like_login} && " + 
        "cd #{options.mirror_path(@config[:work_dir])} && " + 
        "rake deep_test:start_distributed_server " + 
        "OPTIONS=#{options.to_command_line} HOST=#{@config[:address]}"
      end

      def self.new_dispatch_controller(options)
        servers = options.distributed_hosts.map do |host|
          new :address => host, :work_dir => '/tmp'
        end
        MultiTestServerProxy.new(options, servers)
      end
    end
  end
end
