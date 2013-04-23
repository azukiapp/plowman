defmodule Plowman.GitCmds do
  @rg_app_name Regex.compile("^'\/*(?<app_name>[a-zA-Z0-9][a-zA-Z0-9@_-]*).git'$", "g")

  @msg " ! Invalid path."
  @msg "#{@msg}\n ! Syntax is: git@heroku.com:<app>.git where <app> is your app's name."

  def run(cmd) do
    case check_cmd(cmd) do
      {:ok, git_cmd, app_name} ->
        Plowman.ApiServer.gitaction(app_name, git_cmd)
      error -> error
    end
  end

  defp check_cmd(cmd) do
    case String.split(list_to_bitstring(cmd), " ") do
      [git_cmd , path] when git_cmd == "git-receive-pack" or git_cmd == "git-upload-pack" ->
        check_path(path, git_cmd)
      _ ->
        {:error, :invalid_cmd, @msg}
    end
  end

  defp check_path(path, git_cmd) do
    case Regex.captures(elem(@rg_app_name, 1), path) do
      [app_name: app_name] when is_bitstring(app_name) ->
        {:ok, git_cmd, app_name}
      _ ->
        {:error, :invalid_path, @msg}
    end
  end
end
