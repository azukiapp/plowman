Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanApiServerTest do
  use Plowman.Test, target: Plowman.ApiServer, async: true

  @api_host Plowman.Config.config(:api_server)[:host]
  @api_key  Plowman.Config.config(:api_server)[:key]

  setup_all do
    Meck.new(:hackney)
  end

  test "get user by public key" do
    Meck.expect(:hackney, :request, [:get, :_, :_], {:ok, 200, [], [] })
    silence_log do: assert @target.lookupUserByPublicKey('key') === {:ok, 'key' }

    args = [
      :get,
      match_url("\\/internal\\/lookupUserByPublicKey\\?fingerprint=key"),
      [{ "Authorization", " Basic #{:base64.encode(":#{@api_key}")}" }]
    ]
    assert Meck.num_calls(:hackney, :request, args) == 1
  end

  test "handle the error to a user not found" do
    url_err = match_regex(%r/.*\?fingerprint=invalid_key$/)
    Meck.expect(:hackney, :request, [:get, url_err, :_], {:error})
    silence_log do: assert @target.lookupUserByPublicKey('invalid_key') === {
      :error, "Fingerprint invalid_key not found."
    }
  end

  test "send gitaction to valid command" do
    body = [ host: "10.10.10.101", dyno_id: "foobar" ]
    body_json = JSON.generate(body)

    Meck.expect(:hackney, :request, [:post, :_, :_], {:ok, 200, [], :client})
    Meck.expect(:hackney, :body, [:client], {:ok, body_json, :client})
    assert { :ok, body[:host], "#{@api_key}\n#{body[:dyno_id]}\n" }
      === @target.gitaction("app", "git-pack")

    args = [
      :post,
      match_url("\\/internal\\/app\\/gitaction\\?command=git-pack"),
      [{ "Authorization", " Basic #{:base64.encode(":#{@api_key}")}" }]
    ]
    assert Meck.num_calls(:hackney, :request, args) == 1
  end

  teardown_all do
    :meck.unload(:hackney)
  end

  def match_url(url) do
    match_regex(%r/#{@api_host}#{url}/)
  end
end
