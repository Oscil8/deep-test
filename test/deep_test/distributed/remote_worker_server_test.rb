require File.dirname(__FILE__) + "/../../test_helper"

unit_tests do
  test "start_all delegates to worker implementation" do
    server = DeepTest::Distributed::RemoteWorkerServer.new("", "", implementation = mock)
    implementation.expects(:start_all)
    server.start_all
  end

  test "stop_all delegates to worker implementation" do
    server = DeepTest::Distributed::RemoteWorkerServer.new("", "", implementation = mock)
    implementation.expects(:stop_all)
    server.stop_all
  end
  
  test "load_files loads each file in list, replacing source path with mirror path" do
    server = DeepTest::Distributed::RemoteWorkerServer.new("/source/path", "/mirror/dir", stub_everything)
    server.expects(:load).with("/mirror/dir/my/file.rb")
    Dir.expects(:chdir).with("/mirror/dir")
    server.load_files(["/source/path/my/file.rb"])
  end

  test "service is removed after grace period if workers haven't been started" do
    log_level = DeepTest.logger.level
    begin
      DeepTest.logger.level = Logger::ERROR
      DeepTest::Distributed::RemoteWorkerServer.start(
        "", 
        "", 
        stub_everything,
        0.25
      )
      # Have to sleep long enough to warlock to reap dead process
      sleep 1.0
      assert_equal 0, DeepTest::Distributed::RemoteWorkerServer.running_server_count
    ensure
      begin
        DeepTest::Distributed::RemoteWorkerServer.stop_all
      ensure
        DeepTest.logger.level = log_level
      end
    end
  end

  test "service is not removed after grace period if workers have been started" do
    log_level = DeepTest.logger.level
    begin
      DeepTest.logger.level = Logger::ERROR
      server = nil
      capture_stdout do
        server = DeepTest::Distributed::RemoteWorkerServer.start(
          "", 
          "", 
          stub_everything,
          0.25
        )
      end
      server.start_all
      # Have to sleep long enough to warlock to reap dead process
      sleep 1.0
      assert_equal 1, DeepTest::Distributed::RemoteWorkerServer.running_server_count
    ensure
      begin
        DeepTest::Distributed::RemoteWorkerServer.stop_all
      ensure
        DeepTest.logger.level = log_level
      end
    end
  end
end
