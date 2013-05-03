Code.require_file "../test_helper.exs", __FILE__

defmodule PlowmanTest do
  use Plowman.Test, async: false
  import Plowman.Config, only: [config: 1]

  setup_all do
    {:ok, [
      ssh: Mock.new(:ssh, [stub_all: {:ok, :pid}]),
      sup: Mock.new(Plowman.Supervisor, [stub_all: {:ok, :sup}]),
    ]}
  end

  setup meta do
    meta[:ssh].reset!
    meta[:sup].reset!
    {:ok, meta}
  end

  teardown_all meta do
    meta[:ssh].destroy
    meta[:sup].destroy
  end

  test "Call :ssh.daemon with correct parameters", meta do
    host_keys = './test/keys'
    :application.set_env(:plowman, :host_keys, host_keys)

    silence_log do
      assert {:ok, :sup, :pid} === Plowman.start(:type, [])
    end

    assert 1 === meta[:ssh].nc(:daemon, [
      {0, 0, 0, 0},
      config(:port),
      [
        system_dir: Path.expand(host_keys),
        auth_methods: 'publickey',
        key_cb: Plowman.Keys,
        nodelay: true,
        subsystems: [],
        ssh_cli: {Plowman.GitCli, []},
        user_interaction: false
      ]
    ])
  end

  test "resolve correct binding address", meta do
    mock = meta[:ssh]

    {:ok, ip} = :inet.getaddr('localhost', :inet)
    :application.set_env(:plowman, :binding, 'localhost')
    assert {:ok, :sup, :pid} === Plowman.start(:normal, [])
    assert 1 === mock.nc(:daemon, [ip, config(:port), :_])

    mock.reset!
    {:ok, ip} = :inet.getaddr('fe80::1', :inet6)
    :application.set_env(:plowman, :binding, 'fe80::1')
    assert {:ok, :sup, :pid} === Plowman.start(:normal, [])
    assert 1 === mock.nc(:daemon, [ip, config(:port), :_])

    mock.reset!
    :application.set_env(:plowman, :binding, 'invalid::ip::v6')
    assert {:ok, :sup, :pid} === Plowman.start(:normal, [])
    assert 1 === mock.nc(:daemon, [{127, 0, 0, 1}, config(:port), :_])
  end
end
