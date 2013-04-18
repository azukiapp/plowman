defmodule Plowman do
  import Plowman.Config, only: [config: 1]

  def start_link do
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

  def log(msg) do
    IO.inspect(msg)
  end
end
