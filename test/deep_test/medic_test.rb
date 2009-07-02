require File.dirname(__FILE__) + "/../test_helper"

module DeepTest
  unit_tests do
    test "triage is not fatal if a heart monitor of the specified type has beeped in the last 5 seconds" do
      medic = Medic.new
      monitor = at("12:00:00") { medic.assign_monitor :foo }
      at("12:01:01") { monitor.beep }
      at("12:01:06") { assert_equal false, medic.triage(:foo).fatal? }
    end

    test "triage is not fatal if any of multiple heart monitors has beeped" do
      medic = Medic.new
      monitor_1 = at("12:00:00") { medic.assign_monitor :foo }
      monitor_2 = at("12:00:00") { medic.assign_monitor :foo }
      at("12:01:01") { monitor_1.beep }
      at("12:01:06") { assert_equal false, medic.triage(:foo).fatal? }
      at("12:01:07") { monitor_2.beep }
      at("12:01:12") { assert_equal false, medic.triage(:foo).fatal? }
    end

    test "triage is fatal if no heart monitor has beeped for 5 seconds" do
      medic = Medic.new
      at("12:01:00") { medic.assign_monitor :foo }
      at("12:01:06") { assert_equal true, medic.triage(:foo).fatal? }
    end

    test "triage is fatal if monitor beeped more than 5 seconds ago" do
      medic = Medic.new
      monitor = at("12:01:00") { medic.assign_monitor :foo }
      at("12:01:01") { monitor.beep } 
      at("12:01:07") { assert_equal true, medic.triage(:foo).fatal? }
    end

    test "triage is fatal if monitor of another type has beeped" do
      medic = Medic.new
      foo_monitor = at("12:00:00") { medic.assign_monitor :foo }
      at("12:00:00") { medic.assign_monitor :foo }
      at("12:01:01") { foo_monitor.beep }
      at("12:01:06") { assert_equal true, medic.triage(:bar).fatal? }
    end

    test "beep returns nil so nothing is serialized over the wire" do
      assert_equal nil, Medic.new.assign_monitor(:foo).beep
    end

    test "monitor will not be dumped over the wire after assignment" do
      assert_kind_of DRb::DRbUndumped, Medic.new.assign_monitor(:foo)
    end

    def at(time, &block)
      Timewarp.freeze(time, &block)
    end
  end
end
