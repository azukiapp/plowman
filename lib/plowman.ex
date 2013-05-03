defmodule Plowman do
  import Plowman.Config, only: [config: 1]

  def start_link do
    # TODO: Adding ssh host key generation
    options = [
      system_dir: Path.expand(config(:host_keys)),
      auth_methods: 'publickey',
      key_cb: Plowman.Keys,
      nodelay: true,
      subsystems: [],
      ssh_cli: {Plowman.GitCli, []},
      user_interaction: false
    ]

    # Start custom ssh service
    :ssh.daemon(binding, config(:port), options)
  end

  # Convert biding address
  defp binding do
    b = config(:binding)
    case :inet.getaddr(b, :inet) do
      {:ok, addr} -> addr
      {:error, _} -> case :inet.getaddr(b, :inet6) do
        {:ok, addr} -> addr
        {:error, _} -> {127, 0, 0, 1}
      end
    end
  end

  defmacro __using__(_options) do
    my = __MODULE__
    quote do
      require unquote(my)
      import unquote(my), only: [log: 1]
    end
  end

  defmacro log(msg) do
    quote do
      if Mix.env == :dev, do: IO.inspect(unquote(msg))
    end
  end
end
