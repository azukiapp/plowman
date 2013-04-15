defmodule Plowman.Config do
  def config(key) do
    case :application.get_env(:plowman, key) do
      {:ok, value} -> value
      _ -> :undefined
    end
  end
end
