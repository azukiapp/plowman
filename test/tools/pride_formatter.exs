defmodule PrideFormatter do

  @behaviour ExUnit.Formatter
  use GenServer.Behaviour

  @schemes [
    prideio: [:red, :green, :yellow, :blue, :magenta, :cyan],
    pridelol: Enum.map(0..(6*7) - 1, fn (n) ->
      n = n * 1.0 / 6
      r = trunc(3 * :math.sin(n                   ) + 3)
      g = trunc(3 * :math.sin(n + 2 * :math.pi / 3) + 3)
      b = trunc(3 * :math.sin(n + 4 * :math.pi / 3) + 3)

      36 * r + 6 * g + b + 16
    end)
  ]

  defrecord Config, counter: 0, failures: [], next_color: 0, scheme: :prideio

  def suite_started(_opts) do
    { :ok, pid } = :gen_server.start_link(__MODULE__, [], [])
    pid
  end

  defdelegate suite_finished(id, ms), to: ExUnit.CLIFormatter
  defdelegate case_started(id, test_case), to: ExUnit.CLIFormatter
  defdelegate case_finished(id, test_case), to: ExUnit.CLIFormatter
  defdelegate test_started(id, test), to: ExUnit.CLIFormatter
  defdelegate test_finished(id, test), to: ExUnit.CLIFormatter

  ## Callbacks
  def init(_args) do
    scheme = ((Regex.match? %r/^xterm|-256color$/, System.get_env(:TERM)) && :pridelol) || :prideio
    { :ok, Config.new(scheme: scheme, next_color: :random.uniform(Enum.count(@schemes[scheme]))) }
  end

  def handle_cast({ :test_finished, ExUnit.Test[failure: nil] }, config) do
    IO.write success(".", config.next_color, config.scheme)
    { :noreply, config.update_counter(&1 + 1).update_next_color(&1 + 1)}
  end

  defdelegate handle_call(msg, from, config), to: ExUnit.CLIFormatter
  defdelegate handle_cast(msg, config), to: ExUnit.CLIFormatter

  # Print styles
  defp success(msg, index, scheme) do
    color = Enum.at! @schemes[scheme], rem(index, Enum.count(@schemes[scheme]))
    color = case scheme do
      :prideio  -> "%{#{color}}"
      :pridelol -> "\e[38;5;#{color}m"
    end

    IO.ANSI.escape("#{color}" <> msg <> "\e[0m")
  end
end
