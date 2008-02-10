number_of_workers, pattern = ARGV
begin
  require "deep_test"
  warlock = DeepTest::Warlock.new
  Signal.trap("HUP") { warlock.stop_all; exit 0 }
  
  Dir.glob(pattern).each { |file| load file }
  Test::Unit.run = true
  
  # server
  warlock.start "server" do
    DeepTest::Server.start
  end
  sleep 0.25 # TODO: is this necessary?

  # workers
  number_of_workers.to_i.times do |i|
    warlock.start "worker #{i}" do
      srand # re-seed random numbers
      ActiveRecord::Base.connection.reconnect! if defined?(ActiveRecord::Base)
      DeepTest::Worker.new.run
    end
  end

  loader_pid = fork do
    puts "Loader (#{$$})"
    passed = DeepTest::Loader.run
    exit(passed ? 0 : 1)
  end
  Process.wait(loader_pid)
  exit($?.success? ? 0 : 1)
ensure
  warlock.stop_all if warlock
end
