defmodule Plowman.Git_cli do
  @behaviour :ssh_channel
  import Plowman, only: [log: 1]

  @app_name "^'\/*(?<app_name>[a-zA-Z0-9][a-zA-Z0-9@_-]*).git'$"

  defrecord State, channel: nil, cm: nil, group: nil

  def init(options) do
    {:ok, State.new()}
  end

  # TODO: Verify record math and init
  def handle_msg({:ssh_channel_up, channelId, connectionMagager}, _) do
    log(channelId)
    {:ok, State.new(channel: channelId, cm: connectionMagager)}
  end

  def handle_msg({'EXIT', group, _reason}, state = State[group: group, channel: channelId]) do
    {:ok, channelId, state}
  end

  def handle_msg(_data, state) do
    log({"handle_msg", _data})
    {:ok, state}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:exec, channelId, wantReply, cmd}}, state) do
    case check_cmd(cmd) do
      {:error, msg} ->
        write_chars(cm, channelId, "\n ! Invalid path.")
        write_chars(cm, channelId, "\n ! Syntax is: git@heroku.com:<app>.git where <app> is your app's name.\n\n")
        :ssh_connection.reply_equest(cm, wantReply, :failure, channelId)
    end
    {:ok, state}
  end

  def handle_ssh_msg({:ssh_cm, cm, msg}, state) do
    Plowman.log({"handle_ssh_msg", msg})
    wantReply = false
    case msg do
      {:env, channelId, wantReply, _, _ } -> false
      {:pty, channelId, wantReply, _ } -> false
      {:shell, channelId, wantReply} -> false
      {:eof, channelId} -> false
    end
    :ssh_connection.reply_request(cm, wantReply, :failure, channelId)
    {:ok, state}
  end

  def terminate(_reason, _state) do
    Plowman.log({"terminate", _reason, _state})
    :ok
  end

  defp check_cmd(cmd) do
    case String.split(list_to_bitstring(cmd), " ") do
      [git_cmd , path] when git_cmd == "git-receive-pack" or git_cmd == "git-upload-pack" ->
        case Regex.captures(%r/#{@app_name}/g, path) do
          [app_name: app_name] when is_bitstring(app_name) ->
            log({git_cmd, path, app_name})
            {:ok}
          _ ->
            {:error, :invalid_path}
        end
      _ ->
        {:error, :invalid_path}
    end
  end

  defp write_chars(cm, channel, chars) when is_bitstring(chars) do
    write_chars(cm, channel, bitstring_to_list(chars))
  end

  defp write_chars(cm, channel, chars) do
    case :erlang.iolist_size(chars) do
      0 -> {:ok}
      _ -> :ssh_connection.send(cm, channel, 1, chars)
    end
  end
end
