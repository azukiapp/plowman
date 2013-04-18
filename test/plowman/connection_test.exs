Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanConnectionTest do
  use Plowman.Test, async: false
  @t Plowman.Connection

  setup_all do
    mock = Mock.new(:ssh_connection)
    {:ok, [mock: mock]}
  end

  test "call reply_request to failure", meta do
    meta[:mock].stubs(:reply_request, [:cm, false, :failure, :channelId], { :ok })
    assert {:ok} === @t.reply_failure(:cm, false, :channelId)

    meta[:mock].stubs(:reply_request, [:cm1, true, :failure, :channelId], { :ok })
    assert {:ok} === @t.reply_failure(:cm1, true, :channelId)
  end

  test "call send to failure with mensagem", meta do
    meta[:mock].stubs(:reply_request, [:cm, false, :failure, :channelId], { :ok })
    meta[:mock].stubs(:send, [:cm, :channelId, 1, :_], :ok)

    assert {:ok} === @t.reply_failure(:cm, false, :channelId, 'message')
    assert {:ok} === @t.reply_failure(:cm, false, :channelId, "message")

    assert 2 == meta[:mock].nc(:send, [:_, :_, 1, 'message'])
  end

  teardown_all meta do
    meta[:mock].destroy
  end
end
