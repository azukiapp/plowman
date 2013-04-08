defmodule Plowman do
  def start_link do
    :ok = :application.start(:crypto)
    :ok = :application.start(:public_key)
    :ok = :application.start(:ssl)
    :ok = :application.start(:ssh)

    Process.register(spawn(fn -> log() end), :log)
    # myshell = {Plowman.Shell, :start, []}

    options = [
      system_dir: '/Users/nuxlli/Downloads/plowman/certs',
      auth_methods: 'publickey',
      key_cb: Plowman.Keys,
      nodelay: true,
      subsystems: [],
      ssh_cli: {Plowman.Git_cli, []}
      # shell: fn (user) ->
      #   log({user, "master self", self})
      #   {_, gio} = Process.info(self, :group_leader)
      #   spawn_link(__MODULE__, :input_loop, [gio, self])
      # end
    ]

  log({"master self", self})

    {:ok, _pid} = :ssh.daemon({0, 0, 0, 0}, 3333, options)
    # :ssh.shell({0, 0, 0, 0}, 3333, [])
  end

  def input_loop(fd, pid) do
  log({fd, pid})
    IO.write(fd, ">")
    case IO.readline(fd) do
      line ->
    log(line)
        input_loop(fd, pid)
    end
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
