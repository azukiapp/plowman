Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanGitCliTest do
  use Plowman.Test, async: false

  @target Plowman.GitCli
  @state  @target.CliState

  setup_all do
    {:ok, [
      state: @state.new(cm: 'cm', group: 'gp', channel: 'cl'),
      connect: Mock.new(Plowman.Connection),
      cmds: Mock.new(Plowman.GitCmds),
    ]}
  end

  teardown meta do
    meta[:cmds].reset!
  end

  teardown_all meta do
    meta[:connect].destroy
    meta[:cmds].destroy
  end

  test "set new state to init" do
    assert @target.init([]) === {:ok, @state.new()}
  end

  test "return new state for ssh_channel_up" do
    {:ok, r} = @target.handle_msg({:ssh_channel_up, :channelId, :connectionManager}, nil)
    assert r === @state.new(channel: :channelId, cm: :connectionManager)
  end

  test "return channelId and state for EXIT msg" do
    state = @state.new(group: :group, channel: :channel)
    {:ok, rchannel, rstate} = @target.handle_msg({'EXIT', :group, nil}, state)
    assert rchannel == :channel
    assert rstate   == state
  end

  test "return any state for outher handle_msgs" do
    state = @state.new(cm: :any_way)
    assert {:ok, state} === @target.handle_msg({}, state)
  end

  test "return ok for call terminate" do
    assert :ok === @target.terminate(:reason, @state.new())
  end

  test "handle invalid msgs", meta do
    state = meta[:state]
    meta[:connect].stubs(:reply_failure, [:_, :_, state.channel], :ok)

    msgs = [
      {:env, state.channel, true, :var, :value},
      {:pty, state.channel, true, []},
      {:shell, state.channel, true},
      {:eof, state.channel}
    ]

    Enum.each msgs, fn(msg, i) ->
      {cm, wantReply} = {'cm#{i}', element(msg, 2, false)}
      assert {:ok, state} === @target.handle_ssh_msg({:ssh_cm, cm, msg}, state)
      assert 1 == meta[:connect].nc(:reply_failure, [cm, wantReply, state.channel])
    end
  end

  test "send msg and failure to connection with invalid command", meta do
    [state, connect, cmds] = [meta[:state], meta[:connect], meta[:cmds]]

    cmds.stubs(:run, ['fail'], {:error, :invalid_path, "msg"})
    connect.stubs(:reply_failure, [state.cm, false, state.channel, :_], :ok)
    msg = {:ssh_cm, state.cm, {:exec, state.channel, false, 'fail'}}

    assert {:ok, state} == @target.handle_ssh_msg(msg, state)
    assert 1 == cmds.nc(:run, ['fail'])
    assert 1 == connect.nc(:reply_failure, [state.cm, false, state.channel, "\nmsg\n\n"])
  end

  test "connect in dynohost and authentication for valid command", meta do
    Mock.run Plowman.GenServer, [stub_all: {:ok, :dyno}], fn(server) ->
      [state, cmds] = [meta[:state], meta[:cmds]]
      msg  = {:ssh_cm, state.cm, {:exec, state.channel, false, 'cmd'}}

      cmds.stubs(:run, ['cmd'], {:ok, "localhost", 'authkey'})

      assert {:ok, state.dyno(:dyno)} === @target.handle_ssh_msg(msg, state)
      assert 1 == server.nc(:start_link, [Plowman.Dynohost, ["localhost", state], []])
      assert 1 == server.nc(:cast, [:dyno, {:send, 'authkey'}])
    end
  end

  test "forward data msgs to dynohost", meta do
    Mock.run Plowman.GenServer, [stub_all: :ok], fn(server) ->
      state = meta[:state]
      msg   = {:ssh_cm, state.cm, {:data, state.channel, :type, 'foobar'}}
      state = state.dyno(:dyno)

      assert {:ok, state} === @target.handle_ssh_msg(msg, state)
      assert 1 === server.nc(:cast, [:dyno, {:send, 'foobar'}])
    end
  end
end
