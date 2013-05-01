defmodule Plowman.GitCli do
  @behaviour :ssh_channel
  use Plowman

  alias Plowman.Connection, as: Connection
  alias Plowman.GitCmds, as: GitCmds
  alias Plowman.Dynohost, as: Dynohost

  defrecord CliState, [:channel, :cm, :group, :dyno]

  def init(_options) do
    {:ok, CliState.new()}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # TODO: Verify record math and init
  def handle_msg({:ssh_channel_up, channelId, connectionMagager}, _) do
    {:ok, CliState.new(channel: channelId, cm: connectionMagager)}
  end

  def handle_msg({'EXIT', group, _reason}, state = CliState[group: group, channel: channelId]) do
    {:ok, channelId, state}
  end

  def handle_msg(_data, state) do
    log(_data)
    {:ok, state}
  end

  def handle_ssh_msg({:ssh_cm, _cm, {:data, _, _, data}}, CliState[dyno: dyno] = state) do
    Dynohost.send(dyno, data)
    {:ok, state}
  end

  # TODO: Parametrize hostname in example
  def handle_ssh_msg({:ssh_cm, cm, {:exec, channelId, wantReply, cmd}}, state) do
    case GitCmds.run(cmd) do
      {:error, _type, msg} ->
        Connection.reply_failure(cm, wantReply, channelId, "\n#{msg}\n\n")
      {:ok, host, auth} ->
        # Connect and Auth
        {:ok, dyno} = Dynohost.start_link(host, state)
        Dynohost.auth(dyno, auth)
        state = state.dyno(dyno)
    end
    {:ok, state}
  end

  # Don't accept anything other than exec
  def handle_ssh_msg({:ssh_cm, cm, msg}, state) do
    channelId = elem(msg, 1)
    wantReply = try do; elem(msg, 2); rescue; _ -> false; end
    Connection.reply_failure(cm, wantReply, channelId)
    {:ok, state}
  end
end
