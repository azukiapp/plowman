defmodule Plowman.Keys do
  @api_key   "ec1a8eb9-18a6-42c2-81ec-c0f0f615280c"
  @api_host  "https://10.10.10.100:5000"
  @api_entry "/internal/lookupUserByPublicKey?fingerprint="

  def host_key(algorithm, daemonOptions) do
    :ssh_file.host_key(algorithm, daemonOptions)
  end

  def is_auth_key(key, _user, _alg, _daemonOptions) do
    case checkKey(key) do
      {:ok, _result} -> true
      result ->
        IO.inspect(result)
        false
    end
  end

  def checkKey(key) do
    case fingerprint(key) do
      {:ok, cmp_key} ->
        url     = "#{@api_host}#{@api_entry}#{cmp_key}"
        headers = [{"Authorization", " Basic #{:base64.encode(":#{@api_key}")}"}]
        # IO.inspect(url)
        case :hackney.request(:get, url, headers) do
          {:ok, 200, _respHeaders, _client} ->
            # IO.inspect(:hackney.body(client))
            {:ok, cmp_key}
          _ ->
            {:error, "Fingerprint #{cmp_key} not found."}
        end
      _ -> {:error, "Impossible calculate fingerprint"}
    end
  end

  def fingerprint(key) do
    case String.split(:public_key.ssh_encode([{key, []}], :auth_keys)) do
      [_, key | _] ->
        md5 = binary_to_list(:crypto.md5(:base64.decode_to_string(key)))
        {:ok, List.flatten(lc n inlist md5, do: :io_lib.format("~2.16.0b", [n]))}
      _ ->
        {:error, "Key invalid format"}
    end
  end
end
