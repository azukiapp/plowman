Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanApiServerTest do
  use Plowman.Test, async: true

  @target Plowman.ApiServer
  @api_host Plowman.Config.config(:api_server)[:host]
  @api_key  Plowman.Config.config(:api_server)[:key]

  setup do
    Meck.new(:hackney)
  end

  test "valid lookupUserByPublicKey" do
    Meck.expect(:hackney, :request, [:get, :_, :_], {:ok, 200, [], [] })
    assert @target.lookupUserByPublicKey('key') === {:ok, 'key' }

    args = [
      :get,
      match_regex(%r/#{@api_host}\/internal\/lookupUserByPublicKey\?fingerprint=key/),
      [{ "Authorization", " Basic #{:base64.encode(":#{@api_key}")}" }]
    ]
    assert Meck.num_calls(:hackney, :request, args) == 1
  end

  test "invalid lookupUserByPublicKey" do
    url_err = match_regex(%r/.*\?fingerprint=invalid_key$/)
    Meck.expect(:hackney, :request, [:get, url_err, :_], {:error})
    assert @target.lookupUserByPublicKey('invalid_key') === {
      :error, "Fingerprint invalid_key not found."
    }
  end

  teardown do
    :meck.unload(:hackney)
  end
end
