defmodule GameTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Game

  @max_allowed_players 5

  describe "initialization" do
    test "accepts a string name on start" do
      game_id = "ABCD"
      {:ok, _pid} = start_supervised({Game, game_id})
    end

    # TODO>>>> Update to account for start_supervised
    # test "raises exception if name is not a string" do
    #   for non_string_type <- [:name, 7, nil, 'name'] do
    #     assert_raise FunctionClauseError, fn ->
    #       start_supervised({Game, non_string_type}) |> IO.inspect(label: ">>>>")
    #     end
    #   end
    # end
  end

  describe "add_player/2" do
    test "can add max of 5 players" do
      pid = start_supervised!({Game, "game_id"})

      for n <- 1..@max_allowed_players do
        player = "player#{n}"
        assert :ok = Game.add_player(pid, player)
      end

      assert :error = Game.add_player(pid, "player6")
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
      pid = start_supervised!({Game, "game_id"})

      assert :ok = Game.add_player(pid, "player1")
      assert :error = Game.start_game(pid)

      assert :ok = Game.add_player(pid, "player2")
      assert :ok = Game.start_game(pid)
    end
  end
end
