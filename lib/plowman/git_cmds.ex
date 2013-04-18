defmodule Plowman.GitCmds do
  @rg_app_name Regex.compile("^'\/*(?<app_name>[a-zA-Z0-9][a-zA-Z0-9@_-]*).git'$", "g")

  def run(cmd) do
    check_cmd(cmd)
  end

  defp check_cmd(cmd) do
    case String.split(list_to_bitstring(cmd), " ") do
      [git_cmd , path] when git_cmd == "git-receive-pack" or git_cmd == "git-upload-pack" ->
        check_path(path)
      _ ->
        {:error, :invalid_cmd}
    end
  end

  defp check_path(path) do
    case Regex.captures(elem(@rg_app_name, 1), path) do
      [app_name: app_name] when is_bitstring(app_name) ->
        {:ok, app_name}
      _ ->
        {:error, :invalid_path}
    end
  end
end
