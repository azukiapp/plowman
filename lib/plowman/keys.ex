defmodule Plowman.Keys do
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

  # TODO: Tratar melhor os erros do hackney
  defp checkKey(key) do
    case fingerprint(key) do
      {:ok, cmp_key} -> Plowman.ApiServer.lookupUserByPublicKey(cmp_key)
      _ -> {:error, "Impossible calculate fingerprint"}
    end
  end

  defp fingerprint(key) do
    case String.split(:public_key.ssh_encode([{key, []}], :auth_keys)) do
      [_, key | _] ->
        md5 = binary_to_list(:crypto.md5(:base64.decode_to_string(key)))
        {:ok, List.flatten(lc n inlist md5, do: :io_lib.format("~2.16.0b", [n]))}
      _ ->
        {:error, "Key invalid format"}
    end
  end
end
