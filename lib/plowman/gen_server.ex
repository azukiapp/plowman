defmodule Plowman.GenServer do
  defdelegate start_link(module, args, opts), to: :gen_server
  defdelegate cast(pid, msg), to: :gen_server
end
