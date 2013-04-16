Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanKeysTest do
  use Plowman.Test

  @target Plowman.Keys
  @user_key :filename.join([:filename.dirname(__FILE__), "..", "keys", "user_rsa.pub"])

  setup do
    :meck.new(:ssh_file, [:passthrough])
    :meck.new(Plowman.ApiServer)
    :ok
  end

  test "forward host_key to ssh_file" do
    Plowman.Keys.host_key('ssh-rsa', [])
    assert :meck.num_calls(:ssh_file, :host_key, ['ssh-rsa', []]) == 1
  end

  test "calculate fingerprint and call apiserver" do
    {:ok, file_key} = File.read(@user_key)
    [{key, _}]  = :public_key.ssh_decode(file_key, :auth_keys)
    fingerprint = system_fingerprint(@user_key)

    Meck.expect(Plowman.ApiServer, :lookupUserByPublicKey, [fingerprint], {:ok, fingerprint})
    assert @target.is_auth_key(key, nil, nil, nil)
  end

  test "return false to invalid fingerprint" do
    msg = "no function clause matching: :pubkey_ssh.key_type('invalid')"
    assert_raise FunctionClauseError, msg, fn ->
      @target.is_auth_key('invalid', nil, nil, nil)
    end
  end

  teardown do
    :meck.unload(:ssh_file)
    :meck.unload(Plowman.ApiServer)
    :ok
  end

  def system_fingerprint(file) do
    cmd = 'ssh-keygen -lf #{file} | awk \'{ gsub(/\:/, ""); print $2 }\''
    bitstring_to_list(String.strip("#{:os.cmd(cmd)}"))
  end
end
