defmodule Plowman.Config do
  def config(key) do
    case :application.get_env(:plowman, key) do
      {:ok, value} -> value
      _ -> :undefined
    end
  end

  def config(key, env) do
    System.get_env(env) || config(key)
  end

  def config(key, env, true) do
    case config(key, env) do
      << value :: binary >> -> list_to_integer(bitstring_to_list(value))
      value -> value
    end
  end
end
