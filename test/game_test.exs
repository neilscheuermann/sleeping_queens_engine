defmodule GameTest do
  use ExUnit.Case

  describe "start_link/1" do
    test "accepts a string name on start" do
      assert {:ok, _pid} = SleepingQueensEngine.Game.start_link("Tom")
    end

    test "raises exception if name is not a string" do
      assert_raise FunctionClauseError, fn ->
        SleepingQueensEngine.Game.start_link(:name)
      end

      assert_raise FunctionClauseError, fn ->
        SleepingQueensEngine.Game.start_link(7)
      end

      assert_raise FunctionClauseError, fn ->
        SleepingQueensEngine.Game.start_link(nil)
      end
    end
  end
end
