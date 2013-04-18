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
    assert {:ok, "app"}  === @t.run('git-receive-pack \'app.git\'')
    assert {:ok, "node"} === @t.run('git-upload-pack \'/node.git\'')
  end
end
