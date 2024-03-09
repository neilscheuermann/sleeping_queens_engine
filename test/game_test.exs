defmodule GameTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Game
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  @max_allowed_players 5

  describe "initialization" do
    test "accepts a string game_id on start" do
      game_id = "ABCD"
      {:ok, _pid} = start_supervised({Game, game_id})
    end

    # Must call `start_link` directly to assert a raised FunctionClauseError
    # since `start_supervised` returns an error tuple when initialization fails
    test "raises exception if name is not a string" do
      for non_string_type <- [:game_id, 0, nil, 'game_id'] do
        assert_raise FunctionClauseError, fn ->
          Game.start_link(non_string_type)
        end
      end
    end
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
      pid = start_supervised!({Game, "game_id"})

      for non_string_type <- [:name, 0, nil, 'name'] do
        assert_raise FunctionClauseError, fn ->
          Game.add_player(pid, non_string_type)
        end
      end
    end
  end

  describe "start_game/1" do
    test "successfully starts game with minimum of 2 players" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      assert :error = Game.start_game(pid)

      Game.add_player(pid, "player2")
      assert :ok = Game.start_game(pid)
    end
  end

  describe "deal_cards/1" do
    test "returns error if game has not started" do
      pid = start_supervised!({Game, "game_id"})

      assert :error = Game.deal_cards(pid)
    end

    test "successfully deals cards if game has started" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      assert :ok = Game.deal_cards(pid)
    end
  end

  describe "get_state/1" do
    test "returns the expected game state" do
      game_id = "game_id"
      pid = start_supervised!({Game, game_id})

      assert %{
               game_id: ^game_id,
               table: %Table{},
               rules: %Rules{}
             } = Game.get_state(pid)
    end
  end
end
