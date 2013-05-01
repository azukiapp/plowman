Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanDynohostTest do
  use Plowman.Test, async: false
  import Plowman.Config, only: [config: 1]

  @target Plowman.Dynohost
  alias Plowman.GitCli.CliState, as: CliState

  setup_all do
    {:ok, [
      ssl:  Mock.new(:ssl, [stub_all: :ok]),
      conn: Mock.new(:ssh_connection, [stub_all: :ok]),
      process: Mock.new(Process),
    ]}
  end

  setup meta do
    meta[:ssl].reset!
    meta[:ssl].stubs(:connect, [:_, :_, []], {:ok, :socket})
    meta[:ssl].stubs(:controlling_process, [:socket, :_], :ok)

    meta[:process].reset!
    meta[:process].stubs(:spawn, [:_, :_, :_], self)

    meta[:conn].reset!
    {:ok, meta}
  end

  teardown_all meta do
    meta[:conn].destroy
    meta[:ssl].destroy
    meta[:process].destroy
  end

  test "spawn a process, connect to dynohost and start receive", meta do
    port   = config(:dynohost)[:rendezvous_port]
    client = CliState.new()
    state  = @target.SslState.new(client: client, socket: :socket)

    assert {:ok, pid} = @target.start_link("10.10.10.10", client)
    assert is_pid(pid)
    assert 1 == meta[:ssl].nc(:connect,['10.10.10.10', port, []])
    assert 1 == meta[:ssl].nc(:controlling_process, [:socket, self])
    assert 1 == meta[:process].nc(:spawn, [@target, :ssl_receive, [state]])
  end

  test "implements auth and send" do
    {:ok, pid} = @target.start_link("10.10.10.10", CliState.new())
    @target.auth(pid, "foobar")
    assert {:send, :socket, "foobar"} == receive_anywhere()

    @target.send(pid, "barfoo")
    assert {:send, :socket, "barfoo"} == receive_anywhere()
  end

  test "implements terminate" do
    @target.start_link("10.10.10.10", CliState.new())
    assert :ok == @target.terminate(:reanson, @target.SslState.new(listener: self))
    assert :stop == receive_anywhere()
  end

  test "forward data to ssl.send and call in loop", meta do
    self <- {:send, :socket, "foo"}
    self <- {:stop}

    assert :ok == @target.ssl_receive(@target.SslState.new(socket: :socket))
    assert 1 == meta[:ssl].nc(:send, [:socket, "foo"])
  end

  test "forward data to client", meta do
    self <- {:ssl, :socket, 'foo'}
    self <- {:stop}

    state = @target.SslState.new(socket: :socket, client: CliState.new)
    assert :ok == @target.ssl_receive(state)
    assert 1 == meta[:conn].nc(:send, [nil, nil, 0, 'foo'])
  end

  test "forward ssl_closed to client", meta do
    self <- {:ssl_closed, :socket}

    state = @target.SslState.new(socket: :socket, client: CliState.new)
    assert :ok == @target.ssl_receive(state)
    assert 1 == meta[:conn].nc(:exit_status, [nil, nil, 0])
    assert 1 == meta[:conn].nc(:close, [nil, nil])
  end

  defp receive_anywhere do
    receive do
      anywhere -> anywhere
    after
      1000 -> {:error_timeout_receive}
    end
  end
end
