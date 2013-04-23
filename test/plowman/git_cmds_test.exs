Code.require_file "../../test_helper.exs", __FILE__

defmodule PlowmanGitCmdsTest do
  use Plowman.Test, async: true
  @t Plowman.GitCmds

  test "return :invalid_cmd for invalid commands" do
    invalid = {:error, :invalid_cmd}
    assert invalid === @t.run('')
    assert invalid === @t.run('other-command')
  end

  test "return :invalid_path for invalid apps name" do
    invalid = {:error, :invalid_path}
    assert invalid === @t.run('git-receive-pack \'app\'')
    assert invalid === @t.run('git-upload-pack \':app.git\'')
  end

  test "extract app name for valid commands" do
    Mock.run Plowman.ApiServer, fn (mock) ->
      mock.stubs(:gitaction, [:_, :_], { :ok })

      @t.run('git-receive-pack \'app.git\'')
      assert 1 === mock.nc(:gitaction, ["app", "git-receive-pack"])

      @t.run('git-upload-pack \'/node.git\'')
      assert 1 === mock.nc(:gitaction, ["node", "git-upload-pack"])
    end
  end
end
