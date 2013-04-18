defmodule Plowman.ApiServer do
  import Plowman.Config, only: [config: 1]
  @path "/internal/lookupUserByPublicKey?fingerprint="

  # TODO: Refactory to analisy hackney errors
  def lookupUserByPublicKey(key) do
    case get("#{config(:api_server)[:host]}#{@path}#{key}") do
      {:ok, 200, _, _ } -> { :ok, key }
      _ -> {:error, "Fingerprint #{key} not found." }
    end
  end

  # TODO: Adding timeout to request
  defp get(url) do
    :hackney.request(:get, url, headers)
  end

  defp headers do
    key = :base64.encode(":#{config(:api_server)[:key]}")
    [{ "Authorization", " Basic #{key}" }]
  end
end
