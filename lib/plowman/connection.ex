defmodule Plowman.Connection do
  alias Plowman.GitCli.CliState, as: CliState

  def reply_failure(cm, wantReply, channel, msg // nil) do
    if msg != nil, do: write_chars(cm, channel, msg, 1)
    :ssh_connection.reply_request(cm, wantReply, :failure, channel)
  end

  def write_chars(cm, channel, chars) do
    write_chars(cm, channel, chars, 0)
  end

  def write_chars(cm, channel, << chars :: binary >>, type) do
    write_chars(cm, channel, bitstring_to_list(chars), type)
  end

  def write_chars(cm, channel, chars, type) do
    case :erlang.iolist_size(chars) do
      0 -> :ok
      _ -> :ssh_connection.send(cm, channel, type, chars)
    end
  end

  def forward(CliState[cm: cm, channel: channelId], msgs) do
    case msgs do
      <<?E, ?:, data :: binary >> ->
        write_chars(cm, channelId, data, 1)
      << data :: binary >> ->
        write_chars(cm, channelId, data, 0)
      :eof ->
        :ssh_connection.exit_status(cm, channelId, 0)
        :ssh_connection.close(cm, channelId)
      {:error, _reason} ->
        reply_failure(cm, false, channelId, "! Unable to contact build server.")
        :ssh_connection.exit_status(cm, channelId, 1)
        :ssh_connection.close(cm, channelId)
    end
  end
end
