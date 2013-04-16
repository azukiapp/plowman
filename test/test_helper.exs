ExUnit.start

:application.set_env(:plowman, :port, 6789)

defmodule Plowman.Test do
  defmacro __using__(opts) do
    async  = Keyword.get(opts, :async, false)
    parent = Keyword.get(opts, :parent, ExUnit.Case)

    quote do
      use ExUnit.Case, async: unquote(async), parent: unquote(parent)
      use Plowman.Test.Matchers
      alias :meck, as: Meck
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
  end
end
