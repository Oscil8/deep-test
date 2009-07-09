module DeepTest
  module Distributed
    class LandingShip
      def initialize(config)
        @config = config
      end

      def push_code(options)
        path = options.mirror_path(@config[:work_dir])
        RSync.push(@config[:address], options.sync_options, path)
      end

      def establish_beachhead(options)
        output  = `#{ssh_command(options)} '#{spawn_command(options)}' 2>&1`
        output.each do |line|
          if line =~ /Beachhead url: (.*)/
            options.central_command.medic.expect_live_monitors Beachhead
            return DRb::DRbObject.new_with_uri($1)
          end
        end
        raise "LandingShip unable to establish Beachhead.  Output from #{@config[:address]} was:\n#{output}"
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
        "rake deep_test:establish_beachhead " + 
        "OPTIONS=#{options.to_command_line} HOST=#{@config[:address]}"
      end
    end
  end
end
