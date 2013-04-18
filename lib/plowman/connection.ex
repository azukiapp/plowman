defmodule Plowman.Connection do
  def reply_failure(cm, wantReply, channel, msg // nil) do
    if msg != nil, do: write_chars(cm, channel, msg)
    :ssh_connection.reply_request(cm, wantReply, :failure, channel)
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
