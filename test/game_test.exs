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

    test "deals cards and play starts with player1" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: rules, table: table} = Game.get_state(pid)

      assert rules.player_turn == 1

      for player <- table.players do
        assert length(player.hand) == 5
      end
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

  describe "validate_discard_selection/3" do
    test "returns ok when selection is valid and it's player's turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      # can always discard a single card
      card_positions = [1]

      assert {:ok, _waiting_on} =
               Game.validate_discard_selection(
                 pid,
                 player_turn,
                 card_positions
               )
    end

    test "returns error when it's player's turn but selection is invalid" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      # Shouldn't usually directly udpate a gen server's state without using a public fn,
      # but this seems the best option to ensure 2 incompatible cards are selected.
      # This replaces player1's hand with 2 cards that can't be discarded together
      :sys.replace_state(pid, fn current_state ->
        update_in(current_state.table.players, fn players ->
          Enum.map(players, fn player -> 
            if player.position == player_turn do
              %{player | hand: [
                %SleepingQueensEngine.Card{type: :number, name: nil, value: 5},
                %SleepingQueensEngine.Card{type: :knight, name: nil, value: nil}
              ]}
            else
              player
            end
          end)
        end)
      end)

      card_positions = [1, 2]

      assert :error =
               Game.validate_discard_selection(
                 pid,
                 player_turn,
                 card_positions
               )
    end

    test "returns error when selection is valid but it's not player's turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      # can always discard a single card
      card_positions = [1]

      assert :error =
               Game.validate_discard_selection(
                 pid,
                 player_turn + 1,
                 card_positions
               )
    end
  end
end
