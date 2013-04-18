ExUnit.start

:application.set_env(:plowman, :port, 6789)

defmodule Plowman.Test do
  defmacro __using__(opts) do
    async  = Keyword.get(opts, :async, false)
    parent = Keyword.get(opts, :parent, ExUnit.Case)
    my = __MODULE__

    quote do
      use ExUnit.Case, async: unquote(async), parent: unquote(parent)
      use unquote(my).Matchers
      alias :meck, as: Meck
      alias unquote(my).Mock, as: Mock
    end
  end

  defmodule Mock do
    def new(name // list_to_atom('mock-#{:uuid.to_string(:uuid.uuid4())}')) do
      unless is_module?(name), do: (defmodule name do; end)

      # Meck
      :meck.new(name, [:non_strict])
      :meck.expect(name, :stubs, fn (fun, body) ->
          :meck.expect(name, fun, body)
      end)
      :meck.expect(name, :stubs, fn (fun, args, return) ->
          :meck.expect(name, fun, args, return)
      end)

      :meck.expect(name, :destroy, fn
        -> :meck.unload(name); :ok
      end)

      :meck.expect(name, :nc, fn (fun, args) ->
        :meck.num_calls(name, fun, args)
      end)

      # Return module
      name
    end

    defp is_module?(module) when !is_atom(module) do; false; end
    defp is_module?(module) do
      try do
        module.module_info; true
      rescue
        _ -> false
      end
    end
  end

  defmodule Matchers do
    defmacro __using__(_opts) do
      quote do: import Plowman.Test.Matchers
    end

    defmacro match_regex(regex) do
      quote do: :meck.is(fn value ->
        Regex.match?(unquote(regex), value)
      end)
    end

    def element(tuple, index, default // nil) do
      try do
        Kernel.elem(tuple, index)
      rescue
        _ -> default
      end
    end
  end
end
