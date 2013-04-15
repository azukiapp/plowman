Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanKeysTest do
  use ExUnit.Case

  setup do
    :meck.new(:ssh_file, [:passthrough])
    :ok
  end

  test "plow man startable" do
    Plowman.Keys.host_key('ssh-rsa', [])
    assert :meck.num_calls(:ssh_file, :host_key, ['ssh-rsa', []]) == 1
  end

  teardown do
    :meck.unload(:ssh_file)
    :ok
  end
end
