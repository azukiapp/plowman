defmodule Plowman do
  use Application.Behaviour

  require Lager
  import Plowman.Config, only: [config: 2, config: 3]

  def stop(daemon) do
    Lager.info("Plowman stoped")
    :ssh.stop_daemon(daemon)
    :ok
  end

  def exit do
    :application.stop(:plowman)
    System.halt(0)
  end

  def start(_type, _args) do
    port = config(:port, :PLOWMAN_PORT, true)
    keys = config(:host_keys, :PLOWMAN_HOST_KEYS)
    add  = config(:binding, :PLOWMAN_BINDING)

    options = [
      system_dir: Path.expand(keys),
      auth_methods: 'publickey',
      key_cb: Plowman.Keys,
      nodelay: true,
      subsystems: [],
      ssh_cli: {Plowman.GitCli, []},
      user_interaction: false
    ]

    # Start custom ssh service
    {:ok, daemon } = :ssh.daemon(binding(add), port, options)
    {:ok, sup } = Plowman.Supervisor.start_link

    Lager.info("Plowman will listen on #{add}:#{port}")

    {:ok, sup, daemon}
  end

  # Convert biding address
  defp binding(add) do
    case :inet.getaddr(add, :inet) do
      {:ok, addr} -> addr
      {:error, _} -> case :inet.getaddr(add, :inet6) do
        {:ok, addr} -> addr
        {:error, _} -> {127, 0, 0, 1}
      end
    end
  end
end
