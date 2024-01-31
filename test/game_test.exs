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

  describe "add_player/2" do
    test "can add max of 5 players" do
      assert {:ok, pid} = SleepingQueensEngine.Game.start_link("game_id")

      for n <- 1..@max_allowed_players do
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

  describe "start_game/1" do
    test "can start game with minimum of 2 players" do
      assert {:ok, pid} = SleepingQueensEngine.Game.start_link("game_id")
      assert :ok = SleepingQueensEngine.Game.add_player(pid, "player1")
      assert :error = SleepingQueensEngine.Game.start_game(pid)

      assert :ok = SleepingQueensEngine.Game.add_player(pid, "player2")
      assert :ok = SleepingQueensEngine.Game.start_game(pid)
    end
  end
end
