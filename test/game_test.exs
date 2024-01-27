defmodule GameTest do
  use ExUnit.Case

  @max_allowed_players 5

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

  describe "add_player" do
    test "can add max of 5 players" do
      assert {:ok, pid} = SleepingQueensEngine.Game.start_link("player1")

      for n <- 2..@max_allowed_players do
        player = "player#{n}"
        assert :ok = SleepingQueensEngine.Game.add_player(pid, player)
      end

      assert :error = SleepingQueensEngine.Game.add_player(pid, "player6")
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
