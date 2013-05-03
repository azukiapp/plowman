defmodule Plowman.Supervisor do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link {:local, :plowman}, __MODULE__, []
  end

  def init([]) do
    {:ok, {{:one_for_one, 10, 10}, []}}
  end
end
