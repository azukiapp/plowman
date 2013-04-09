defmodule Plowman do
  def start_link do
    # Starting subsytems systems
    :ok = :application.start(:crypto)
    :ok = :application.start(:public_key)
    :ok = :application.start(:ssl)
    :ok = :application.start(:ssh)

    Process.register(spawn(fn -> log() end), :log)

    # TODO: Adding ssh host key generation
    options = [
      system_dir: '/Users/nuxlli/Downloads/egit/certs',
      auth_methods: 'publickey',
      key_cb: Plowman.Keys,
      nodelay: true,
      subsystems: [],
      ssh_cli: {Plowman.Git_cli, []},
      user_interaction: false
    ]

    # Start custom ssh service
    {:ok, _pid} = :ssh.daemon({0, 0, 0, 0}, 3333, options)
  end

  def log(msg) do
    Process.whereis(:log) <- {:log, msg}
  end

  def log do
    receive do
      {:log, msg} ->
        IO.inspect(msg)
        log()
    end
  end
end
