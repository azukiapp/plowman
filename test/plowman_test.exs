Code.require_file "../test_helper.exs", __FILE__

defmodule PlowmanTest do
  use ExUnit.Case

  test "plow man startable" do
    assert {:ok, _} = Plowman.start_link()
  end
end
