defmodule GameTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Game
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table
  alias SleepingQueensEngine.QueenCard

  @max_allowed_players 5
  @max_allowed_cards_in_hand 5
  @expected_draw_pile_size 68

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

      assert [%QueenCard{}] =
               updated_players
               |> Enum.find(&(&1.position == player_turn))
               |> Map.get(:queens)

      assert waiting_on == nil
      assert updated_player_turn == player_turn + 1

      for player <- updated_players do
        assert length(player.hand) == @max_allowed_cards_in_hand
      end
    end

    test "successfully ends game when player selects enough queens" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_position}} = Game.get_state(pid)

      queens = [
        %QueenCard{value: 20, special?: false, name: ""},
        %QueenCard{value: 10, special?: false, name: ""},
        %QueenCard{value: 10, special?: false, name: ""}
      ]

      replace_player_queens_with(pid, player_position, queens)

      queen_card = %QueenCard{value: 10, special?: false, name: ""}
      queen_coordinate = {1, 1}
      place_queen_on_board_at_location(pid, queen_card, queen_coordinate)

      set_waiting_on(pid, %{
        action: :select_queen,
        player_position: player_position
      })

      {row, col} = queen_coordinate
      assert :ok = Game.select_queen(pid, player_position, row, col)

      assert %{rules: %{state: :game_over}} = Game.get_state(pid)
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

      set_player_turn(pid, opponent_position)

      set_waiting_on(pid, %{
        action: :select_queen,
        player_position: opponent_position
      })

      row = 1
      col = 1
      :ok = Game.select_queen(pid, opponent_position, row, col)

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

  describe "lose_queen/1" do
    test "successfully lose queen to player whose turn it is when stolen, nil next waiting on and queen to lose" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)
      player_position = 1
      opponent_position = 2

      set_waiting_on(pid, %{
        action: :select_queen,
        player_position: opponent_position
      })

      set_player_turn(pid, opponent_position)

      row = 1
      col = 1
      Game.select_queen(pid, opponent_position, row, col)
      opponent_queen_position = 1

      set_waiting_on(pid, %{
        action: :block_steal_queen,
        player_position: opponent_position
      })

      set_queen_to_lose(pid, %{
        player_position: opponent_position,
        queen_position: opponent_queen_position
      })

      # Test/Assert
      assert :ok = Game.lose_queen(pid)

      %{rules: rules, table: %{players: updated_players}} = Game.get_state(pid)

      assert [] =
               updated_players
               |> Enum.find(&(&1.position == opponent_position))
               |> Map.get(:queens)

      assert [%QueenCard{}] =
               updated_players
               |> Enum.find(&(&1.position == player_position))
               |> Map.get(:queens)

      assert %{waiting_on: nil, queen_to_lose: nil} = rules
    end

    test "successfully sets game state to game_over when player stealing queen makes player win" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)
      player_position = 1
      opponent_position = 2

      queens = [
        %QueenCard{value: 20, special?: false, name: ""},
        %QueenCard{value: 10, special?: false, name: ""},
        %QueenCard{value: 10, special?: false, name: ""}
      ]

      replace_player_queens_with(pid, player_position, queens)

      opponent_queens = [%QueenCard{value: 10, special?: false, name: ""}]
      replace_player_queens_with(pid, opponent_position, opponent_queens)
      opponent_queen_position = 1

      set_waiting_on(pid, %{
        action: :block_steal_queen,
        player_position: opponent_position
      })

      set_queen_to_lose(pid, %{
        player_position: opponent_position,
        queen_position: opponent_queen_position
      })

      # Test/Assert
      assert :ok = Game.lose_queen(pid)

      assert %{rules: %{state: :game_over}} = Game.get_state(pid)
    end

    test "successfully update waiting on when lose queen to putting back on board" do
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

      set_waiting_on(pid, %{
        action: :block_place_queen_back_on_board,
        player_position: opponent_position
      })

      set_queen_to_lose(pid, %{
        player_position: opponent_position,
        queen_position: opponent_queen_position
      })

      assert :ok = Game.lose_queen(pid)

      %{rules: %{queen_to_lose: queen_to_lose}} = Game.get_state(pid)

      assert %{
               rules: %{
                 waiting_on: %{
                   action: :pick_spot_to_return_queen,
                   player_position: ^player_turn
                 },
                 queen_to_lose: ^queen_to_lose
               }
             } = Game.get_state(pid)
    end

    test "returns error when incorrect waiting_on action" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      for waiting_on_action <- [:draw_for_jester, :select_queen] do
        set_waiting_on(pid, %{
          action: waiting_on_action,
          player_position: player_turn
        })

        assert :error = Game.lose_queen(pid)
      end
    end

    test "returns error when correct waiting_on action but missing queen to lose" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.start_game(pid)

      %{rules: %{player_turn: player_turn}} = Game.get_state(pid)

      for waiting_on_action <- [:steal_queen, :place_queen_back_on_board] do
        set_waiting_on(pid, %{
          action: waiting_on_action,
          player_position: player_turn
        })

        assert :error = Game.lose_queen(pid)
      end
    end
  end

  # Scenarios
  # Player selects a queen (from a king or a jester)
  # Player steals a queen from an opponent
  describe "restart_game/1" do
    test "resets the table as needed and increments each player position by one" do
      pid = start_supervised!({Game, "game_id"})

      Game.add_player(pid, "player1")
      Game.add_player(pid, "player2")
      Game.add_player(pid, "player3")
      Game.start_game(pid)
      player_position = 1

      # set player queens
      queens = [
        %QueenCard{value: 20, special?: false, name: ""},
        %QueenCard{value: 10, special?: false, name: ""},
        %QueenCard{value: 10, special?: false, name: ""}
      ]

      replace_player_queens_with(pid, player_position, queens)

      # set next queen to draw
      queen_card = %QueenCard{value: 10, special?: false, name: ""}
      queen_coordinate = {1, 1}
      place_queen_on_board_at_location(pid, queen_card, queen_coordinate)

      set_waiting_on(pid, %{
        action: :select_queen,
        player_position: player_position
      })

      # Draw the queen to end the game
      %{rules: %{state: :playing}} = Game.get_state(pid)
      {row, col} = queen_coordinate
      :ok = Game.select_queen(pid, player_position, row, col)
      %{rules: %{state: :game_over}} = Game.get_state(pid)

      # Test/Assert
      assert :ok = Game.restart_game(pid)

      game_state = Game.get_state(pid)
      rules = game_state.rules
      table = game_state.table

      # rules
      assert %{
               state: :initialized,
               player_count: 3,
               player_turn: 1,
               waiting_on: nil,
               queen_to_lose: nil
             } = rules

      # draw_pile, discard pile
      assert length(table.draw_pile) == @expected_draw_pile_size
      assert %{discard_pile: []} = table

      # queens board
      assert Enum.all?(table.queens_board, fn {_coord, queen} ->
               not is_nil(queen)
             end)

      # player hand and queens
      assert Enum.all?(table.players, &(&1.hand == [] and &1.queens == []))

      # players positions incremented correctly
      assert Enum.find(table.players, &(&1.name == "player1")).position == 2
      assert Enum.find(table.players, &(&1.name == "player2")).position == 3
      assert Enum.find(table.players, &(&1.name == "player3")).position == 1

      # players positions are valid
      player_positions = Enum.map(table.players, & &1.position)
      unique_player_positions = Enum.uniq(player_positions)

      assert Enum.sort(player_positions) == Enum.sort(unique_player_positions)
      assert Enum.all?(player_positions, &(&1 in 1..rules.player_count))
    end
  end

  # NOTE:
  # Shouldn't usually directly udpate a gen server's state without using a public fn,
  # but this seems the best option to ensure 2 incompatible cards are selected.
  # This replaces player1's hand with 2 cards that can't be discarded together

  ###
  # State helper functions
  #

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

  defp replace_player_queens_with(pid, player_position, new_queens) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.table.players, fn players ->
        Enum.map(players, fn player ->
          if player.position == player_position do
            %{player | queens: new_queens}
          else
            player
          end
        end)
      end)
    end)
  end

  defp place_queen_on_board_at_location(pid, queen_card, queen_coordinate) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.table.queens_board, fn queens_board ->
        Map.replace(queens_board, queen_coordinate, queen_card)
      end)
    end)
  end

  defp replace_draw_pile_with(pid, card) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.table.draw_pile, fn _draw_pile -> [card] end)
    end)
  end

  defp set_player_turn(pid, player_turn) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.rules, fn rules ->
        %{rules | player_turn: player_turn}
      end)
    end)
  end

  defp set_waiting_on(pid, waiting_on) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.rules, fn rules ->
        %{rules | waiting_on: waiting_on}
      end)
    end)
  end

  defp set_queen_to_lose(pid, queen_to_lose) do
    :sys.replace_state(pid, fn current_state ->
      update_in(current_state.rules, fn rules ->
        %{rules | queen_to_lose: queen_to_lose}
      end)
    end)
  end
end
