Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanConnectionTest do
  use Plowman.Test, async: false
  @target Plowman.Connection

  alias Plowman.GitCli.CliState, as: CliState

  setup_all do
    {:ok, [
      client: CliState.new(cm: :cm, channel: :channelId),
      conn: Mock.new(:ssh_connection, [stub_all: :ok])
    ]}
  end

  teardown meta do
    meta[:conn].reset!
  end

  test "call reply_request to failure" do
    assert :ok == @target.reply_failure(:cm, false, :channelId)
    assert :ok == @target.reply_failure(:cm1, true, :channelId)
  end

  test "call send to failure with mensagem", meta do
    assert :ok == @target.reply_failure(:cm, false, :channelId, 'message')
    assert :ok == @target.reply_failure(:cm, false, :channelId, "message")
    assert :ok == @target.reply_failure(:cm, false, :channelId, "")

    assert 2 == meta[:conn].nc(:send, [:_, :_, 1, 'message'])
  end

  test "write chars for valid binary to call forward", meta do
    client = meta[:client]

    assert :ok == @target.forward(client, "foo")
    assert 1 == meta[:conn].nc(:send, [client.cm, client.channel, 0, 'foo'])
  end

  test "write in error channel invalid date", meta do
    client = meta[:client]

    assert :ok == @target.forward(client, "E:foo")
    assert 1 == meta[:conn].nc(:send, [client.cm, client.channel, 1, 'foo'])
  end

  test "send exit code 0 and close connection for eof", meta do
    client = meta[:client]

    assert :ok == @target.forward(client, :eof)
    assert 1 == meta[:conn].nc(:exit_status, [client.cm, client.channel, 0])
    assert 1 == meta[:conn].nc(:close, [client.cm, client.channel])
  end

  test "send a fail message, exit code 1 and close connection for error", meta do
    client = meta[:client]

    assert :ok == @target.forward(client, {:error, :reason})
    msg = '! Unable to contact build server.'
    assert 1 == meta[:conn].nc(:reply_request, [client.cm, false, :failure, client.channel])
    assert 1 == meta[:conn].nc(:send, [client.cm, client.channel, 1, msg])
    assert 1 == meta[:conn].nc(:exit_status, [client.cm, client.channel, 1])
    assert 1 == meta[:conn].nc(:close, [client.cm, client.channel])
  end

  teardown_all meta do
    meta[:conn].destroy
  end
end
