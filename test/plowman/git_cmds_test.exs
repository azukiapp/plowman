Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanGitCmdsTest do
  use Plowman.Test, async: false
  @t Plowman.GitCmds

  @msg_rg %r/^ ! Invalid path.*?\n.*name\.$/m

  test "return :invalid_cmd for invalid commands" do
    Enum.each ['', 'other-command'], fn(cmd) ->
      case @t.run(cmd) do
        {:error, :invalid_cmd, msg} ->
          assert Regex.match?(@msg_rg, msg)
      end
    end
  end

  test "return :invalid_path for invalid apps name" do
    cmds = ['git-receive-pack \'app\'', 'git-upload-pack \':app.git\'']
    Enum.each cmds, fn(cmd) ->
      case @t.run(cmd) do
        {:error, :invalid_path, msg} ->
          assert Regex.match?(@msg_rg, msg)
      end
    end
  end

  test "extract and send app and cmd to apiserver" do
    Mock.run Plowman.ApiServer, fn (mock) ->
      mock.stubs(:gitaction, [:_, :_], { :ok })

      @t.run('git-receive-pack \'app.git\'')
      assert 1 === mock.nc(:gitaction, ["app", "git-receive-pack"])

      @t.run('git-upload-pack \'/node.git\'')
      assert 1 === mock.nc(:gitaction, ["node", "git-upload-pack"])
    end
  end

  test "return error from apiserver" do
    Mock.run :hackney, fn (mock) ->
      mock.stubs(:request, [:post, :_, :_], {:error, 400})
      assert Plowman.ApiServer.gitaction('app', 'git-receive-pack')
        === @t.run('git-receive-pack \'app.git\'')
    end
  end
end
