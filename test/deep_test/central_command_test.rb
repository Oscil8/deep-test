require File.dirname(__FILE__) + "/../test_helper"

module DeepTest
  unit_tests do
    test "take_work returns result of push_work when it is available" do
      central_command = CentralCommand.new Options.new({})
      central_command.write_work :work
      assert_equal :work, central_command.take_work
    end

    test "take_work raises error when no work is currently available" do
      assert_raises(CentralCommand::NoWorkUnitsAvailableError) do
        CentralCommand.new(Options.new({})).take_work
      end
    end

    test "take_work raises error when there is no work left to" do
      central_command = CentralCommand.new Options.new({})
      central_command.done_with_work

      assert_raises(CentralCommand::NoWorkUnitsRemainingError) do
        central_command.take_work
      end
    end

    test "take_result returns argument to write_result when it is available" do
      central_command = CentralCommand.new Options.new({})
      central_command.medic.assign_monitor Agent
      t = Thread.new {central_command.take_result}
      central_command.write_result :result
      assert_equal :result, t.value
    end

    test "take_result raises NoAgentsRunningError if agent triage is fatal when it is called" do
      central_command = CentralCommand.new Options.new({}) 
      at("12:00:00") { central_command.medic.assign_monitor Agent }
      at("12:00:06") do
        assert_raises(CentralCommand::NoAgentsRunningError) {central_command.take_result}
      end
    end

    test "write_work returns nil" do
      central_command = CentralCommand.new Options.new({})
      assert_equal nil, central_command.write_work(:a)
    end

    test "write_result returns nil" do
      central_command = CentralCommand.new Options.new({})
      assert_equal nil, central_command.write_result(:a)
    end

    test "start returns instance of central_command" do
      DRb::DRbServer.expects(:new).returns stub(:uri => "druby://host:1111")
      central_command = CentralCommand.start Options.new({})
      assert_kind_of CentralCommand, central_command
    end

    test "start uses server port specifed in options" do
      DRb::DRbServer.expects(:new).with(regexp_matches(/:9999/), anything).returns stub(:uri => "druby://host:1111")
      CentralCommand.start Options.new(:server_port => 9999)
    end

    test "start sets server_port in options if none was specified" do
      DRb::DRbServer.expects(:new).with(regexp_matches(/:0/), anything).returns(stub(:uri => "druby://host:50101"))

      options = Options.new(:server_port => nil)
      CentralCommand.start options
      assert_equal 50101, options.server_port
    end
  end
end
