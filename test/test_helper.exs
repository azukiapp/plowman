Code.require_file "../tools/mock.exs", __FILE__

ExUnit.start

:application.set_env(:plowman, :port, 6789)

defmodule Plowman.Test do
  defmacro __using__(opts) do
    async  = Keyword.get(opts, :async, false)
    parent = Keyword.get(opts, :parent, ExUnit.Case)
    target = Keyword.get(opts, :target, nil)
    my = __MODULE__

    quote do
      use ExUnit.Case, async: unquote(async), parent: unquote(parent)
      use unquote(my).Matchers
      alias :meck, as: Meck
      require Mock
      if unquote(target) != nil do
        @target unquote(target)
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
