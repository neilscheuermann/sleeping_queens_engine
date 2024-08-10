defmodule GameTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Game
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  @max_allowed_players 5
  @max_allowed_cards_in_hand 5

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

      assert {:ok, nil = _waiting_on} =
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

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :number,
          name: nil,
          value: 5
        },
        %SleepingQueensEngine.Card{
          type: :knight,
          name: nil,
          value: nil
        }
      ]

      replace_player_hand_with(pid, player_turn, new_hand)

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

  describe "discard/3" do
    test "successfully discards, deals, and advances player turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{
        rules: %{player_turn: player_turn},
        table: %{discard_pile: discard_pile, draw_pile: draw_pile}
      } = Game.get_state(pid)

      # can always discard a single card
      card_positions = [1]

      assert :ok = Game.discard(pid, player_turn, card_positions)

      %{
        rules: %{player_turn: updated_player_turn},
        table: %{
          discard_pile: updated_discard_pile,
          draw_pile: updated_draw_pile,
          players: updated_players
        }
      } = Game.get_state(pid)

      assert updated_player_turn == player_turn + 1
      assert length(updated_discard_pile) == length(discard_pile) + 1
      assert length(updated_draw_pile) == length(draw_pile) - 1

      for player <- updated_players do
        assert length(player.hand) == @max_allowed_cards_in_hand
      end
    end

    test "returns error when it's player's turn but selection is invalid" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :number,
          name: nil,
          value: 5
        },
        %SleepingQueensEngine.Card{
          type: :knight,
          name: nil,
          value: nil
        }
      ]

      replace_player_hand_with(pid, player_turn, new_hand)

      card_positions = [1, 2]

      assert :error = Game.discard(pid, player_turn, card_positions)
    end

    test "returns error when selection is valid but it's not player's turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      # can always discard a single card
      card_positions = [1]

      assert :error = Game.discard(pid, player_turn + 1, card_positions)
    end
  end

  describe "validate_play_selection/3" do
    test "returns ok when selection is valid and it's player's turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :king,
          name: "name1"
        }
      ]

      replace_player_hand_with(pid, player_turn, new_hand)

      card_positions = [1]

      assert {:ok, _waiting_on} =
               Game.validate_play_selection(
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

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :number,
          name: nil,
          value: 5
        }
      ]

      replace_player_hand_with(pid, player_turn, new_hand)

      card_positions = [1]

      assert :error =
               Game.validate_play_selection(
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

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :king,
          name: "name1"
        }
      ]

      replace_player_hand_with(pid, player_turn + 1, new_hand)

      card_positions = [1]

      assert :error =
               Game.validate_play_selection(
                 pid,
                 player_turn + 1,
                 card_positions
               )
    end
  end

  describe "play/3" do
    test "successfully discards and sets waiting_on" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{
        rules: %{player_turn: player_turn},
        table: %{discard_pile: discard_pile}
      } = Game.get_state(pid)

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :king,
          name: "name1"
        }
      ]

      replace_player_hand_with(pid, player_turn, new_hand)

      card_positions = [1]

      assert :ok = Game.play(pid, player_turn, card_positions)

      %{
        rules: %{waiting_on: waiting_on},
        table: %{discard_pile: updated_discard_pile}
      } = Game.get_state(pid)

      assert %{action: :select_queen, player_position: 1} = waiting_on
      assert length(updated_discard_pile) == length(discard_pile) + 1
    end

    test "returns error when it's player's turn but selection is invalid" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :number,
          name: nil,
          value: 5
        }
      ]

      replace_player_hand_with(pid, player_turn, new_hand)

      card_positions = [1]

      assert :error = Game.play(pid, player_turn, card_positions)
    end

    test "returns error when selection is valid but it's not player's turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      new_hand = [
        %SleepingQueensEngine.Card{
          type: :king,
          name: "name1"
        }
      ]

      replace_player_hand_with(pid, player_turn + 1, new_hand)

      card_positions = [1]

      assert :error = Game.play(pid, player_turn + 1, card_positions)
    end
  end

  describe "select_queen/4" do
    test "successfully moves queen to player, deals cards, resets waiting_on, and advances player turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, %{
        action: :select_queen,
        player_position: player_turn
      })

      row = 1
      col = 1

      assert :ok = Game.select_queen(pid, player_turn, row, col)

      %{
        rules: %{player_turn: updated_player_turn, waiting_on: waiting_on},
        table: %{players: updated_players, queens_board: queens_board}
      } = Game.get_state(pid)

      assert Map.get(queens_board, {row, col}) == nil

      assert [%SleepingQueensEngine.QueenCard{}] =
               updated_players
               |> Enum.find(&(&1.position == player_turn))
               |> Map.get(:queens)

      assert waiting_on == nil
      assert updated_player_turn == player_turn + 1

      for player <- updated_players do
        assert length(player.hand) == @max_allowed_cards_in_hand
      end
    end

    test "returns error when it's player's turn but not correct waiting_on" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, nil)

      row = 1
      col = 1

      assert :error = Game.select_queen(pid, player_turn, row, col)
    end

    test "returns error when wrong player tries to select a queen" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, %{
        action: :select_queen,
        player_position: player_turn + 1
      })

      row = 1
      col = 1

      assert :error = Game.select_queen(pid, player_turn, row, col)
    end

    test "returns error when it's waiting on player to select a queen but the coordinates are invalid" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, %{
        action: :select_queen,
        player_position: player_turn
      })

      row = 99
      col = 99

      assert :error = Game.select_queen(pid, player_turn, row, col)
    end
  end

  describe "draw_for_jester/4" do
    test "sets correct waiting_on when drawing a number and doesn't change player turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, %{
        action: :draw_for_jester,
        player_position: player_turn
      })

      replace_draw_pile_with(pid, %SleepingQueensEngine.Card{
        type: :number,
        name: nil,
        value: 1
      })

      assert :ok = Game.draw_for_jester(pid, player_turn)

      assert %{
               rules: %{
                 player_turn: ^player_turn,
                 waiting_on: %{
                   action: :select_queen,
                   player_position: ^player_turn
                 }
               }
             } = Game.get_state(pid)
    end

    test "sets correct waiting_on when drawing an action card and doesn't change player turn" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, %{
        action: :draw_for_jester,
        player_position: player_turn
      })

      replace_player_hand_with(pid, player_turn, [])
      replace_draw_pile_with(pid, %SleepingQueensEngine.Card{type: :wand})

      assert :ok = Game.draw_for_jester(pid, player_turn)

      assert %{
               rules: %{
                 player_turn: ^player_turn,
                 waiting_on: nil
               }
             } = Game.get_state(pid)
    end

    test "returns error when it's player's turn but not correct waiting_on" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, nil)

      assert :error = Game.draw_for_jester(pid, player_turn)
    end

    test "returns error when wrong player tries to draw for jester" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      set_waiting_on(pid, %{
        action: :draw_for_jester,
        player_position: player_turn + 1
      })

      assert :error = Game.draw_for_jester(pid, player_turn)
    end
  end

  describe "select_opponent_queen/4" do
    test "successfully updates waiting on and queen to lose when selecting opponent queen" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)
      opponent_position = player_turn + 1

      row = 1
      col = 1
      Game.select_queen(pid, opponent_position, row, col)

      opponent_queen_position = 1

      for waiting_on_action <- [:steal_queen, :place_queen_back_on_board] do
        set_waiting_on(pid, %{
          action: waiting_on_action,
          player_position: player_turn
        })

        assert :ok =
                 Game.select_opponent_queen(
                   pid,
                   player_turn,
                   opponent_position,
                   opponent_queen_position
                 )

        expected_next_action =
          case waiting_on_action do
            :steal_queen -> :block_steal_queen
            :place_queen_back_on_board -> :block_place_queen_back_on_board
          end

        assert %{
                 rules: %{
                   waiting_on: %{
                     action: ^expected_next_action,
                     player_position: ^opponent_position
                   },
                   queen_to_lose: %{
                     player_position: ^opponent_position,
                     queen_position: ^opponent_queen_position
                   }
                 }
               } = Game.get_state(pid)
      end
    end

    test "returns error when correct waiting on player but incorrect waiting_on action" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)
      opponent_position = player_turn + 1

      for waiting_on_action <- [:draw_for_jester, :block_steal_queen] do
        set_waiting_on(pid, %{
          action: waiting_on_action,
          player_position: player_turn
        })

        assert :error =
                 Game.select_opponent_queen(
                   pid,
                   player_turn,
                   opponent_position,
                   1
                 )
      end
    end

    test "returns error when wrong player tries to select opponent queen" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)
      opponent_position = player_turn + 1

      for waiting_on_action <- [:steal_queen, :place_queen_back_on_board] do
        set_waiting_on(pid, %{
          action: waiting_on_action,
          player_position: player_turn
        })

        assert :error =
                 Game.select_opponent_queen(
                   pid,
                   player_turn + 1,
                   opponent_position,
                   1
                 )
      end
    end
  end

  # Shouldn't usually directly udpate a gen server's state without using a public fn,
  # but this seems the best option to ensure 2 incompatible cards are selected.
  # This replaces player1's hand with 2 cards that can't be discarded together
  defp replace_player_hand_with(pid, player_position, new_hand) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.table.players, fn players ->
        Enum.map(players, fn player ->
          if player.position == player_position do
            %{player | hand: new_hand}
          else
            player
          end
        end)
      end)
    end)
  end

  defp replace_draw_pile_with(pid, card) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.table.draw_pile, fn _draw_pile -> [card] end)
    end)
  end

  defp set_waiting_on(pid, waiting_on) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.rules, fn rules ->
        %{rules | waiting_on: waiting_on}
      end)
    end)
  end
end
