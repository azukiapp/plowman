defmodule Plowman.ApiServer do
  import Plowman.Config, only: [config: 1]

  @lookup_url    "/internal/lookupUserByPublicKey?fingerprint=~s"
  @gitaction_url "/internal/~s/gitaction?command=~s"

  # TODO: Refactory to analisy hackney errors
  """
   Find user sending a key to api server
  """
  def lookupUserByPublicKey(key) do
    case get(@lookup_url, [key]) do
      {:ok, 200, _, client } ->
        { :ok, key }
      _ -> {:error, "Fingerprint #{key} not found." }
    end
  end

  # TODO: Refactory to analisy hackney errors
  """
   Send a commando to apiserver
  """
  def gitaction(app, command) do
    case post(@gitaction_url, [app, command]) do
      {:ok, 200, _, client } ->
        {:ok, body, _} = :hackney.body(client)
        body = JSON.parse(body)
        {:ok, body["host"], body["dyno_id"]}
      _ -> {:error, "! Unable to contact build server."}
    end
  end

  # TODO: Adding timeout to request
  defp get(url, options), do: request(:get, url, options)
  defp post(url, options), do: request(:post, url, options)

  defp request(method, url, options) do
    url  = "#{config(:api_server)[:host]}#{:io_lib.format(url, options)}"
    :hackney.request(method, url, headers)
  end

  defp headers do
    key = :base64.encode(":#{config(:api_server)[:key]}")
    [{ "Authorization", " Basic #{key}" }]
  end
end
