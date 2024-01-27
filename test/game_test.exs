defmodule GameTest do
  use ExUnit.Case

  describe "start_link/1" do
    test "accepts a string name on start" do
      assert {:ok, _pid} = SleepingQueensEngine.Game.start_link("Tom")
    end

    test "raises exception if name is not a string" do
      for non_string_type <- [:name, 7, nil, 'name'] do
        assert_raise FunctionClauseError, fn ->
          SleepingQueensEngine.Game.start_link(non_string_type)
        end
      end
    end
  end
end
