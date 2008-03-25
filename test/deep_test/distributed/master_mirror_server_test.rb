require File.dirname(__FILE__) + "/../../test_helper"

unit_tests do
  test "show_status renders status of all servers as html" do
    status = DeepTest::Distributed::MirrorServerStatus.new(
      "binding_uri", 
      5,
      3
    )

    mirror_server = mock(:__drburi => "drburi_1", :status => status) 
    server = DeepTest::Distributed::MasterMirrorServer.new([mirror_server])
    res = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
    server.show_status(:req, res)

    assert_match "<td>binding_uri</td>", res.body
    assert_match "<td>5</td>", res.body
    assert_match "<td>3</td>", res.body
  end

  test "show_status display error message if exception occurs" do
    mirror_server = mock(:__drburi => "drburi_1")
    mirror_server.expects(:status).raises("An Error")

    server = DeepTest::Distributed::MasterMirrorServer.new([mirror_server])

    res = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
    server.show_status(:req, res)

    assert_match /<td.*?>An Error<\/td>/, res.body
  end
end
