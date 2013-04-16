defmodule Plowman do
  import Plowman.Config, only: [config: 1]

  def start_link do
    start_log

    # TODO: Adding ssh host key generation
    options = [
      system_dir: '/Users/nuxlli/Downloads/egit/certs',
      auth_methods: 'publickey',
      key_cb: Plowman.Keys,
      nodelay: true,
      subsystems: [],
      ssh_cli: {Plowman.GitCli, []},
      user_interaction: false
    ]

    # Start custom ssh service
    {:ok, _pid} = :ssh.daemon({0, 0, 0, 0}, config(:port), options)
  end

  def start_log do
    Process.register(spawn(fn -> log() end), :log)
  end

  def log(msg) do
    Process.whereis(:log) <- {:log, self, msg}
    receive do
      :ok -> :ok
    end
  end

  defp log do
    receive do
      {:log, pid, msg} ->
        IO.inspect(msg)
        pid <- :ok
        log()
    end
  end
end
