defmodule Plowman.GitCli do
  @behaviour :ssh_channel
  use Plowman

  defrecord State, [:channel, :cm, :group]

  def init(_options) do
    {:ok, State.new()}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # TODO: Verify record math and init
  def handle_msg({:ssh_channel_up, channelId, connectionMagager}, _) do
    {:ok, State.new(channel: channelId, cm: connectionMagager)}
  end

  def handle_msg({'EXIT', group, _reason}, state = State[group: group, channel: channelId]) do
    {:ok, channelId, state}
  end

  def handle_msg(_data, state) do
    {:ok, state}
  end

  # TODO: Parametrize hostname in example
  def handle_ssh_msg({:ssh_cm, cm, {:exec, channelId, wantReply, cmd}}, state) do
    case Plowman.GitCmds.run(cmd) do
      {:error, _type, msg} ->
        Plowman.Connection.reply_failure(cm, wantReply, channelId, "\n#{msg}\n\n")
      result ->
        log(result)
    end
    {:ok, state}
  end

  # Don't accept anything other than exec
  def handle_ssh_msg({:ssh_cm, cm, msg}, state) do
    channelId = elem(msg, 1)
    wantReply = try do; elem(msg, 2); rescue; _ -> false; end
    Plowman.Connection.reply_failure(cm, wantReply, channelId)
    {:ok, state}
  end
end
