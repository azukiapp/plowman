Code.require_file "../test_helper.exs", __FILE__

defmodule PlowmanTest do
  use Plowman.Test, async: false
  import Plowman.Config, only: [config: 1]

  test "Call :ssh.daemon with correct parameters" do
    host_keys = './test/keys'
    :application.set_env(:plowman, :host_keys, host_keys)

    Mock.run :ssh, [{:stub_all, {:ok, :pid}}], fn (mock) ->
      assert {:ok, :pid} === Plowman.start_link
      assert 1 === mock.nc(:daemon, [
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
  end

  test "resolve correct binding address" do
    Mock.run :ssh, [{:stub_all, {:ok, :pid}}], fn (mock) ->
      {:ok, ip} = :inet.getaddr('localhost', :inet)
      :application.set_env(:plowman, :binding, 'localhost')
      assert {:ok, :pid} === Plowman.start_link
      assert 1 === mock.nc(:daemon, [ip, config(:port), :_])

      mock.reset!
      {:ok, ip} = :inet.getaddr('fe80::1', :inet6)
      :application.set_env(:plowman, :binding, 'fe80::1')
      assert {:ok, :pid} === Plowman.start_link
      assert 1 === mock.nc(:daemon, [ip, config(:port), :_])

      mock.reset!
      :application.set_env(:plowman, :binding, 'invalid::ip::v6')
      assert {:ok, :pid} === Plowman.start_link
      assert 1 === mock.nc(:daemon, [{127, 0, 0, 1}, config(:port), :_])
    end
  end
end
