defmodule Plowman.Git_cli do
  @behaviour :ssh_channel
  import Plowman, only: [log: 1]

  # @SSH_EXTENDED_DATA_DEFAULT 0

  defrecord State, channel: nil, cm: nil, group: nil

  def init(options) do
    Plowman.log({"init", options})
    {:ok, State.new()}
  end

  def handle_msg({:ssh_channel_up, channelId, connectionMagager}, _) do
    {:ok, State.new(channel: channelId, cm: connectionMagager)}
  end

  def handle_msg({'EXIT', group, _reason}, state = State[group: group, channel: channelId]) do
    {:ok, channelId, state}
  end

  def handle_msg(_, state) do
    {:ok, state}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:env, channelId, wantReply, _var, _value}}, state) do
    :ssh_connection.reply_request(cm, wantReply, :failure, channelId)
    {:ok, state}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:shell, channelId, wantReply}}, state) do
    fail = :ssh_connection.channel_open_failure_msg
    # write_chars(cm, channelId, "! It's no a shell")
    # :ssh_connection.reply_request(cm, wantReply, :failure, channelId)
    # :ssh_connection.exit_status(cm, channelId, 0)
    # :ssh_connection.send_eof(cm, channelId)
    # {:stop, channelId, State.new(cm: cm, channel: channelId)}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:exec, channelId, wantReply, cmd}}, state) do
    case String.split(list_to_bitstring(cmd), " ") do
      ["git-receive-pack", path] ->
        log(path)
        {:ok, State.new(cm: cm, channel: channelId)}
      ["git-upload-pack", path] ->
        log(path)
        {:ok, State.new(cm: cm, channel: channelId)}
      _ ->
        write_chars(cm, channelId, "! Falha")
        :ssh_connection.reply_request(cm, wantReply, :failure, channelId)
        :ssh_connection.exit_status(cm, channelId, 0)
        :ssh_connection.send_eof(cm, channelId)
        {:stop, channelId, State.new(cm: cm, channel: channelId)}
    end
  end

  def handle_ssh_msg(connect, state) do
    Plowman.log({"handle_ssh_msg", connect, state})
    {:ok, state}
  end

  def terminate(_reason, _state) do
    Plowman.log({"terminate", _reason, _state})
    :ok
  end

  def write_chars(cm, channel, chars) when is_bitstring(chars) do
    write_chars(cm, channel, bitstring_to_list(chars))
  end

  def write_chars(cm, channel, chars) do
    case :erlang.iolist_size(chars) do
      0 -> {:ok}
      _ -> :ssh_connection.send(cm, channel, 0, chars)
    end
  end
end
