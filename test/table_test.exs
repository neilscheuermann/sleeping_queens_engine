defmodule TableTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  @expected_draw_pile_size 68
  @max_allowed_players 5
  @max_allowed_cards_in_hand 5
  @player1_position 1
  @player2_position 2
  @queen_position 1
  @queen_coordinate {1, 1}
  @invalid_queen_coordinate {10, 10}
  @invalid_queen_position 20

  describe "selected_enough_cards?/1 defguard" do
    require Table

    test "succeeds when is one card up to max number of cards allowed in hand" do
      valid_cases =
        for n <- 1..@max_allowed_cards_in_hand, do: Enum.to_list(1..n)

      Enum.each(valid_cases, fn cards ->
        assert Table.selected_enough_cards?(cards)
      end)
    end

    test "fails when none are selected or more than allowed" do
      invalid_cases = [
        [],
        Enum.to_list(1..(@max_allowed_cards_in_hand + 1))
      ]

      Enum.each(invalid_cases, fn cards ->
        refute Table.selected_enough_cards?(cards)
      end)
    end
  end

  describe "new/1" do
    test "returns a table with required fields and assigns positions when given a list of players" do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")

      assert is_nil(player1.position)
      assert is_nil(player2.position)

      players = [player1, player2]
      table = Table.new(players)

      assert %Table{
               discard_pile: [],
               draw_pile: [%Card{} | _rest],
               players: players,
               queens_board: %{}
             } = table

      player1 = Enum.find(players, &(&1.name == player1.name))
      player2 = Enum.find(players, &(&1.name == player2.name))

      assert player1.position == 1
      assert player2.position == 2
    end
  end

  describe "add_player/2" do
    test "successfully adds a player to the table" do
      player1 = Player.new("Ron")
      table = Table.new([player1])

      new_player = Player.new("Leslie")
      assert {:ok, table} = Table.add_player(table, new_player)

      new_player = Enum.find(table.players, &(&1.name == new_player.name))
      assert length(table.players) == 2
      assert new_player.position == 2
    end

    test "errors if there are already max allowed players at the table" do
      players =
        for n <- 1..@max_allowed_players do
          Player.new("Name#{n}")
        end

      table = Table.new(players)
      new_player = Player.new("Jerry")

      assert {:error, :max_allowed_players_reached} =
               Table.add_player(table, new_player)
    end

    test "raises error if Player struct is not provided" do
      player1 = Player.new("Ron")
      table = Table.new([player1])

      assert_raise FunctionClauseError, fn ->
        not_a_player_struct = %{name: "Leslie"}

        Table.add_player(table, not_a_player_struct)
      end
    end
  end

  describe "deal_cards/1" do
    test "returns an updated table, having dealt cards from the draw pile to players until they each have 5 cards" do
      table = Table.new([Player.new("Ron"), Player.new("Leslie")])

      assert Enum.all?(table.players, &(&1.hand == []))
      assert length(table.draw_pile) == @expected_draw_pile_size

      table = Table.deal_cards(table)

      assert Enum.all?(
               table.players,
               &(length(&1.hand) == @max_allowed_cards_in_hand)
             )

      assert length(table.draw_pile) ==
               @expected_draw_pile_size -
                 length(table.players) * @max_allowed_cards_in_hand
    end

    test "successfully deals cards starting with given position, dealing sequentially to each player who needs cards" do
      table =
        Table.new([
          Player.new("Ron"),
          Player.new("Leslie"),
          Player.new("Donna")
        ])

      player1_position = 1
      player2_position = 2
      player3_position = 3

      three_cards =
        for _ <- 1..3 do
          %Card{type: :king}
        end

      five_cards =
        for _ <- 1..5 do
          %Card{type: :king}
        end

      simplified_draw_pile = [
        %Card{type: :number, value: 1},
        %Card{type: :number, value: 2},
        %Card{type: :number, value: 3},
        %Card{type: :number, value: 4}
      ]

      player1 = update_player_hand(table, player1_position, three_cards)
      player2 = update_player_hand(table, player2_position, five_cards)
      player3 = update_player_hand(table, player3_position, three_cards)

      table =
        table
        |> update_draw_pile(simplified_draw_pile)
        |> update_players([player1, player2, player3])

      assert length(table.draw_pile) == 4

      table = Table.deal_cards(table, player1_position)

      player1 = Table.get_player(table, player1_position)
      player2 = Table.get_player(table, player2_position)
      player3 = Table.get_player(table, player3_position)

      # Confirm only dealt to players 1 and 3, sequentially
      assert [_, _, _, %Card{value: 1}, %Card{value: 3}] = player1.hand
      assert Enum.all?(player2.hand, &(&1.type == :king))
      assert [_, _, _, %Card{value: 2}, %Card{value: 4}] = player3.hand
      assert table.draw_pile == []
    end

    test "successfully reshuffles the deck and finishes dealing when draw pile runs out" do
      table = Table.new([Player.new("Ron"), Player.new("Leslie")])

      [first_card | rest] = table.draw_pile

      table =
        table
        |> update_draw_pile([first_card])
        |> update_discard_pile(rest)

      assert Enum.all?(table.players, &(&1.hand == []))
      assert length(table.draw_pile) == 1
      assert length(table.discard_pile) == @expected_draw_pile_size - 1

      table = Table.deal_cards(table)

      assert Enum.all?(
               table.players,
               &(length(&1.hand) == @max_allowed_cards_in_hand)
             )

      assert length(table.draw_pile) ==
               @expected_draw_pile_size -
                 length(table.players) * @max_allowed_cards_in_hand
    end
  end

  describe "discard_cards/3" do
    setup do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")
      players = [player1, player2]

      table =
        players
        |> Table.new()
        |> Table.deal_cards()

      %{table: table}
    end

    test "success: returns an updated table, having discarded the player's selected card",
         %{table: table} do
      card_positions = [1]

      assert {:ok, updated_table} =
               Table.discard_cards(table, card_positions, @player1_position)

      updated_player1 =
        Enum.find(updated_table.players, &(&1.position == @player1_position))

      assert length(updated_player1.hand) ==
               @max_allowed_cards_in_hand - length(card_positions)

      assert length(updated_table.discard_pile) == length(card_positions)
    end

    test "success with multiple card positions: returns an updated table, having discarded the player's selected cards",
         %{table: table} do
      card_positions = [1, 2]

      assert {:ok, updated_table} =
               Table.discard_cards(table, card_positions, @player1_position)

      updated_player1 =
        Enum.find(updated_table.players, &(&1.position == @player1_position))

      assert length(updated_player1.hand) ==
               @max_allowed_cards_in_hand - length(card_positions)

      assert length(updated_table.discard_pile) == length(card_positions)
    end

    test "error: returns error if no cards are selected",
         %{table: table} do
      card_positions = []

      assert {:error, :invalid_card_selections} =
               Table.discard_cards(table, card_positions, @player1_position)
    end

    test "error: returns error if too many cards are selected",
         %{table: table} do
      card_positions = [1, 2, 3, 4, 5, 6]

      assert {:error, :invalid_card_selections} =
               Table.discard_cards(table, card_positions, @player1_position)
    end
  end

  describe "select_queen/3" do
    setup do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")
      players = [player1, player2]

      table =
        players
        |> Table.new()
        |> Table.deal_cards()

      %{table: table}
    end

    test "success: if selecting dog queen when already have cat queen (and vice versa) returns the table unchanged and an updated waiting_on to notify player",
         %{table: table} do
      for {queen_name_in_hand, queen_name_on_board} <- [
            {"cat", "dog"},
            {"dog", "cat"}
          ] do
        # add dog or cat queen to player's hand
        player1_queens = [
          %QueenCard{name: queen_name_in_hand, value: 15, special?: true}
        ]

        table =
          update_player_queens_with(table, @player1_position, player1_queens)

        # put other on table
        queen_card = %QueenCard{
          name: queen_name_on_board,
          value: 15,
          special?: true
        }

        table =
          place_queen_on_board_at_location(table, queen_card, @queen_coordinate)

        # try to pick up other queen
        assert {:ok, updated_table, next_waiting_on} =
                 Table.select_queen(table, @queen_coordinate, @player1_position)

        player1 =
          Enum.find(updated_table.players, &(&1.position == @player1_position))

        assert [
                 %QueenCard{
                   name: ^queen_name_in_hand,
                   value: 15,
                   special?: true
                 }
               ] = player1.queens

        # make sure queen remains on board
        assert %QueenCard{name: ^queen_name_on_board} =
                 updated_table.queens_board[@queen_coordinate]

        # and next waiting on prompts the player to acknowledge they couldn't pick up the queen
        assert %{
                 action: :acknowledge_blocked_by_dog_or_cat_queen,
                 player_position: @player1_position
               } = next_waiting_on
      end
    end

    test "success: if selecting rose queen it returns updated table and updated waiting_on to notify player to select another queen",
         %{table: table} do
      # put rose queen on table
      queen_card = %QueenCard{name: "rose", value: 5, special?: true}

      table =
        place_queen_on_board_at_location(table, queen_card, @queen_coordinate)

      # pick it up
      assert {:ok, updated_table, next_waiting_on} =
               Table.select_queen(table, @queen_coordinate, @player1_position)

      # assert player picked up the rose queen
      player1 =
        Enum.find(updated_table.players, &(&1.position == @player1_position))

      assert [%QueenCard{name: "rose", value: 5, special?: true}] =
               player1.queens

      # no more queen at that position
      refute updated_table.queens_board[@queen_coordinate]

      # and next waiting on prompts the player to acknowledge they couldn't pick up the queen
      assert %{
               action: :select_another_queen_from_rose,
               player_position: @player1_position
             } = next_waiting_on
    end

    test "success: returns an updated table, having moved selected queen from board to player's queens pile",
         %{table: table} do
      assert %QueenCard{} = table.queens_board[@queen_coordinate]
      assert Enum.all?(table.players, &(&1.queens == []))

      assert {:ok, updated_table, _next_waiting_on} =
               Table.select_queen(table, @queen_coordinate, @player1_position)

      updated_player1 =
        Enum.find(updated_table.players, &(&1.position == @player1_position))

      refute updated_table.queens_board[@queen_coordinate]
      assert [%QueenCard{}] = updated_player1.queens
    end

    test "success: if selecting a dog queen as first queen returns an updated table, having moved selected queen from board to player's queens pile",
         %{table: table} do
      # put rose queen on table
      queen_card = %QueenCard{name: "dog", value: 15, special?: true}

      table =
        place_queen_on_board_at_location(table, queen_card, @queen_coordinate)

      assert %QueenCard{} = table.queens_board[@queen_coordinate]
      assert Enum.all?(table.players, &(&1.queens == []))

      assert {:ok, updated_table, nil} =
               Table.select_queen(table, @queen_coordinate, @player1_position)

      updated_player1 =
        Enum.find(updated_table.players, &(&1.position == @player1_position))

      refute updated_table.queens_board[@queen_coordinate]
      assert [%QueenCard{}] = updated_player1.queens
    end

    test "error: returns error if no queen at valid coordinate",
         %{table: table} do
      assert {:ok, updated_table, _next_waiting_on} =
               Table.select_queen(
                 table,
                 @queen_coordinate,
                 @player1_position
               )

      assert {:error, :no_queen_at_that_position} =
               Table.select_queen(
                 updated_table,
                 @queen_coordinate,
                 @player1_position
               )
    end

    test "error: returns error with invalid coordinate integers",
         %{table: table} do
      assert {:error, :invalid_coordinate} =
               Table.select_queen(
                 table,
                 @invalid_queen_coordinate,
                 @player1_position
               )
    end
  end

  describe "place_queen_on_board/4," do
    setup do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")
      players = [player1, player2]

      table =
        players
        |> Table.new()
        |> Table.deal_cards()

      # select queen and confirm it is with player1 and not on the board
      {:ok, table, _} =
        Table.select_queen(table, @queen_coordinate, @player1_position)

      player_queen =
        table
        |> get_player(@player1_position)
        |> get_queen(@queen_position)

      assert %QueenCard{} = player_queen
      refute Map.get(table.queens_board, @queen_coordinate)

      %{
        table: table
      }
    end

    test "successfully returns an updated table, having moved player queen back to queens board",
         %{table: table} do
      # move player's queen back to queens board
      {:ok, table} =
        Table.place_queen_on_board(
          table,
          @player1_position,
          @queen_position,
          @queen_coordinate
        )

      # confirm queen is back on the board and not with player
      player_queen =
        table
        |> get_player(@player1_position)
        |> get_queen(@queen_position)

      refute player_queen
      assert Map.get(table.queens_board, @queen_coordinate)
    end

    test "errors if queen already exists at valid coordinate",
         %{table: table} do
      occupied_queen_coordinate = {1, 2}

      # try placing where a queen exists
      assert {:error, :queen_exists_at_coordinate} =
               Table.place_queen_on_board(
                 table,
                 @player1_position,
                 @queen_position,
                 occupied_queen_coordinate
               )
    end

    test "errors with invalid coordinate",
         %{table: table} do
      assert {:error, :invalid_coordinate} =
               Table.place_queen_on_board(
                 table,
                 @player1_position,
                 @queen_position,
                 @invalid_queen_coordinate
               )
    end

    test "errors if no queen in that player's queen position",
         %{table: table} do
      assert {:error, :no_queen_at_that_position} =
               Table.place_queen_on_board(
                 table,
                 @player1_position,
                 @invalid_queen_position,
                 @queen_coordinate
               )
    end
  end

  describe "steal_queen/4" do
    setup do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")
      players = [player1, player2]

      table =
        players
        |> Table.new()
        |> Table.deal_cards()

      # select queen and confirm it is with player1 and not on the board
      {:ok, table, _} =
        Table.select_queen(table, @queen_coordinate, @player1_position)

      player_queen =
        table
        |> get_player(@player1_position)
        |> get_queen(@queen_position)

      assert %QueenCard{} = player_queen
      refute Map.get(table.queens_board, @queen_coordinate)

      %{
        table: table
      }
    end

    test "successfully returns an updated table, having moved player1's queen to player2's queens pile",
         %{table: table} do
      # move player's queen back to queens board
      {:ok, table} =
        Table.steal_queen(
          table,
          @player1_position,
          @queen_position,
          @player2_position
        )

      # confirm queen is with player2 and not player1
      player1_queen =
        table
        |> get_player(@player1_position)
        |> get_queen(@queen_position)

      player2_queen =
        table
        |> get_player(@player2_position)
        |> get_queen(@queen_position)

      refute player1_queen
      assert player2_queen
    end

    test "errors if no queen in that player's queen position",
         %{table: table} do
      assert {:error, :no_queen_at_that_position} =
               Table.steal_queen(
                 table,
                 @player1_position,
                 @invalid_queen_position,
                 @player2_position
               )
    end
  end

  describe "draw_for_jester/4" do
    setup do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")
      players = [player1, player2]
      table = Table.new(players)

      %{
        table: table
      }
    end

    test "successfully returns an updated table with card in player's hand if action card, and nil for next waiting_on",
         %{table: table} do
      rules = %Rules{
        state: :playing,
        player_count: 2,
        player_turn: 1,
        waiting_on: %{
          player_position: 1,
          action: :draw_for_jester
        }
      }

      table =
        update_in(table.draw_pile, fn _draw_pile -> [%Card{type: :king}] end)

      assert {:ok, table, waiting_on} =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )

      assert table.draw_pile == []
      assert table.discard_pile == []

      assert Enum.find(table.players, &(&1.position == 1)).hand == [
               %Card{type: :king}
             ]

      assert waiting_on == nil
    end

    test "successfully returns an updated table with card discarded if number card, and next waiting_on indicating correct player to draw a queen",
         %{table: table} do
      rules = %Rules{
        state: :playing,
        player_count: 2,
        player_turn: 1,
        waiting_on: %{
          action: :draw_for_jester,
          player_position: 1
        }
      }

      table =
        update_in(table.draw_pile, fn _draw_pile ->
          [%Card{type: :number, value: 4}]
        end)

      assert {:ok, table, waiting_on} =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )

      assert table.draw_pile == []
      assert table.discard_pile == [%Card{type: :number, value: 4}]

      assert waiting_on == %{
               action: :select_queen,
               player_position: 2
             }
    end

    test "selects the correct person to pickup the queen based on player's turn and number card",
         %{table: table} do
      # scenario 1
      rules = %Rules{
        state: :playing,
        player_count: 5,
        player_turn: 2,
        waiting_on: %{
          action: :draw_for_jester,
          player_position: 2
        }
      }

      table =
        update_in(table.draw_pile, fn _draw_pile ->
          [%Card{type: :number, value: 7}]
        end)

      assert {:ok, _, waiting_on} =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )

      assert waiting_on == %{
               action: :select_queen,
               player_position: 3
             }

      # scenario 2
      rules = %Rules{
        state: :playing,
        player_count: 3,
        player_turn: 3,
        waiting_on: %{
          action: :draw_for_jester,
          player_position: 3
        }
      }

      table =
        update_in(table.draw_pile, fn _draw_pile ->
          [%Card{type: :number, value: 2}]
        end)

      assert {:ok, _, waiting_on} =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )

      assert waiting_on == %{
               action: :select_queen,
               player_position: 1
             }

      # scenario 3
      rules = %Rules{
        state: :playing,
        player_count: 2,
        player_turn: 1,
        waiting_on: %{
          action: :draw_for_jester,
          player_position: 1
        }
      }

      table =
        update_in(table.draw_pile, fn _draw_pile ->
          [%Card{type: :number, value: 10}]
        end)

      assert {:ok, _, waiting_on} =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )

      assert waiting_on == %{
               action: :select_queen,
               player_position: 2
             }
    end

    test "successfully reshuffles the deck and draws card when the draw pile runs out",
         %{table: table} do
      rules = %Rules{
        state: :playing,
        player_count: 2,
        player_turn: 1,
        waiting_on: %{
          player_position: 1,
          action: :draw_for_jester
        }
      }

      table = update_in(table.draw_pile, fn _draw_pile -> [] end)

      table =
        update_in(table.discard_pile, fn _draw_pile -> [%Card{type: :king}] end)

      assert {:ok, table, waiting_on} =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )

      assert table.draw_pile == []
      assert table.discard_pile == []

      assert Enum.find(table.players, &(&1.position == 1)).hand == [
               %Card{type: :king}
             ]

      assert waiting_on == nil
    end

    test "errors if wrong waiting_on action",
         %{table: table} do
      rules = %Rules{
        state: :playing,
        player_count: 2,
        player_turn: 1,
        waiting_on: %{
          player_position: 1,
          action: :steal_queen
        }
      }

      assert :error =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )
    end

    test "errors if nil waiting_on",
         %{table: table} do
      rules = %Rules{
        state: :playing,
        player_count: 2,
        player_turn: 1,
        waiting_on: nil
      }

      assert :error =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )
    end

    test "errors if waiting_on :draw_for_jester but not waiting on player_position",
         %{table: table} do
      rules = %Rules{
        state: :playing,
        player_count: 2,
        player_turn: 1,
        waiting_on: %{
          player_position: 2,
          action: :steal_queen
        }
      }

      assert :error =
               Table.draw_for_jester(
                 table,
                 rules,
                 rules.player_turn
               )
    end
  end

  describe "others_have_a_stealable_queen?/4" do
    setup do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")
      player3 = Player.new("Tom")
      players = [player1, player2, player3]
      table = Table.new(players)

      %{
        table: table
      }
    end

    test "false when 1 other player has the non-stealable strawberry queen", %{
      table: table
    } do
      current_player = Enum.at(table.players, 0)
      other_player = Enum.at(table.players, 1)

      queen_card = %QueenCard{
        name: "strawberry",
        value: 10,
        special?: true
      }

      table =
        place_queen_on_board_at_location(table, queen_card, @queen_coordinate)

      {:ok, table, _} =
        Table.select_queen(table, @queen_coordinate, other_player.position)

      assert false ==
               Table.others_have_a_stealable_queen?(
                 table,
                 current_player.position
               )
    end

    test "true when 1 other player has a stealable queen", %{table: table} do
      current_player = Enum.at(table.players, 0)
      other_player = Enum.at(table.players, 1)

      queen_card = %QueenCard{
        name: "not strawberry",
        value: 10,
        special?: false
      }

      table =
        place_queen_on_board_at_location(table, queen_card, @queen_coordinate)

      {:ok, table, _} =
        Table.select_queen(table, @queen_coordinate, other_player.position)

      assert true ==
               Table.others_have_a_stealable_queen?(
                 table,
                 current_player.position
               )
    end

    test "true when 2+ other players have a queen", %{table: table} do
      current_player = Enum.at(table.players, 0)
      other_player1 = Enum.at(table.players, 1)
      other_player2 = Enum.at(table.players, 2)

      {:ok, table, _} =
        Table.select_queen(table, {1, 1}, other_player1.position)

      {:ok, table, _} =
        Table.select_queen(table, {1, 2}, other_player2.position)

      assert Table.others_have_a_stealable_queen?(
               table,
               current_player.position
             )
    end

    test "false when current player has a queen", %{table: table} do
      current_player = Enum.at(table.players, 0)

      {:ok, table, _} =
        Table.select_queen(table, {1, 1}, current_player.position)

      refute Table.others_have_a_stealable_queen?(
               table,
               current_player.position
             )
    end

    test "false when no one has a queen", %{table: table} do
      current_player = Enum.at(table.players, 0)

      refute Table.others_have_a_stealable_queen?(
               table,
               current_player.position
             )
    end
  end

  describe "win_check/4" do
    # TODO::: Maybe use property testing library that Cristiano mentioned at work.
    # Would that make this implementation easier?
    setup ctx do
      {:ok, player_count: ctx[:player_count]}
    end

    for player_count <- 2..3 do
      @tag player_count: player_count
      test "reports win when player has <5 queens but 50 points in a #{player_count} player game",
           %{player_count: player_count} do
        players =
          for player_number <- 1..player_count do
            Player.new("player#{player_number}")
          end

        table = Table.new(players)
        second_player_position = 2

        queens = [
          %QueenCard{value: 20, special?: false, name: ""},
          %QueenCard{value: 10, special?: false, name: ""},
          %QueenCard{value: 10, special?: false, name: ""},
          %QueenCard{value: 10, special?: false, name: ""}
        ]

        table = update_player_queens_with(table, second_player_position, queens)

        {:win, ^second_player_position} = Table.win_check(table)
      end

      @tag player_count: player_count
      test "reports win when player has <50 points but 5 queens in a #{player_count} player game",
           %{player_count: player_count} do
        players =
          for player_number <- 1..player_count do
            Player.new("player#{player_number}")
          end

        table = Table.new(players)
        second_player_position = 2

        queens = [
          %QueenCard{value: 5, special?: false, name: ""},
          %QueenCard{value: 5, special?: false, name: ""},
          %QueenCard{value: 5, special?: false, name: ""},
          %QueenCard{value: 5, special?: false, name: ""},
          %QueenCard{value: 5, special?: false, name: ""}
        ]

        table = update_player_queens_with(table, second_player_position, queens)

        {:win, ^second_player_position} = Table.win_check(table)
      end
    end

    for player_count <- 4..5 do
      @tag player_count: player_count
      test "reports win when player has <4 queens but 40 points in a #{player_count} player game",
           %{player_count: player_count} do
        players =
          for player_number <- 1..player_count do
            Player.new("player#{player_number}")
          end

        table = Table.new(players)
        second_player_position = 2

        queens = [
          %QueenCard{value: 20, special?: false, name: ""},
          %QueenCard{value: 10, special?: false, name: ""},
          %QueenCard{value: 10, special?: false, name: ""}
        ]

        table = update_player_queens_with(table, second_player_position, queens)

        {:win, ^second_player_position} = Table.win_check(table)
      end

      @tag player_count: player_count
      test "reports win when player has <40 points but 4 queens in a #{player_count} player game",
           %{player_count: player_count} do
        players =
          for player_number <- 1..player_count do
            Player.new("player#{player_number}")
          end

        table = Table.new(players)
        second_player_position = 2

        queens = [
          %QueenCard{value: 5, special?: false, name: ""},
          %QueenCard{value: 5, special?: false, name: ""},
          %QueenCard{value: 5, special?: false, name: ""},
          %QueenCard{value: 5, special?: false, name: ""}
        ]

        table = update_player_queens_with(table, second_player_position, queens)

        {:win, ^second_player_position} = Table.win_check(table)
      end
    end
  end

  describe "player_card_position_for_type/3" do
    setup do
      player1 = Player.new("Ron")
      player2 = Player.new("Leslie")
      players = [player1, player2]
      table = Table.new(players)

      %{
        table: table
      }
    end

    test "returns first matching card position (nil if no match)", %{
      table: table
    } do
      player_position = 1

      new_hand = [
        %Card{type: :wand, name: nil},
        %Card{type: :number, name: nil, value: 1},
        %Card{type: :dragon, name: nil},
        %Card{type: :number, name: nil, value: 2},
        %Card{type: :jester, name: nil}
      ]

      table = replace_player_hand_with(table, player_position, new_hand)

      assert nil ==
               Table.player_card_position_for_type(
                 table,
                 player_position,
                 :not_a_type
               )

      assert nil ==
               Table.player_card_position_for_type(
                 table,
                 player_position,
                 :king
               )

      assert 1 ==
               Table.player_card_position_for_type(
                 table,
                 player_position,
                 :wand
               )

      assert 2 ==
               Table.player_card_position_for_type(
                 table,
                 player_position,
                 :number
               )

      assert 3 ==
               Table.player_card_position_for_type(
                 table,
                 player_position,
                 :dragon
               )

      assert 5 ==
               Table.player_card_position_for_type(
                 table,
                 player_position,
                 :jester
               )
    end

    test "returns nil if no cards", %{table: table} do
      player_position = 1

      new_hand = []
      table = replace_player_hand_with(table, player_position, new_hand)

      assert nil ==
               Table.player_card_position_for_type(
                 table,
                 player_position,
                 :jester
               )
    end
  end

  ###
  # Private Functions
  #

  defp get_player(table, player_position),
    do: Enum.find(table.players, &(&1.position == player_position))

  defp get_queen(player, queen_position),
    do: Enum.at(player.queens, queen_position - 1)

  defp update_player_queens_with(table, player_position, new_queens) do
    update_in(table.players, fn players ->
      Enum.map(players, fn player ->
        if player.position == player_position do
          %{player | queens: new_queens}
        else
          player
        end
      end)
    end)
  end

  defp update_player_hand(table, player_position, new_hand) do
    table.players
    |> Enum.find(&(&1.position == player_position))
    |> update_in([Access.key!(:hand)], fn _hand -> new_hand end)
  end

  defp replace_player_hand_with(table, player_position, new_hand) do
    update_in(table.players, fn players ->
      Enum.map(players, fn player ->
        if player.position == player_position do
          %{player | hand: new_hand}
        else
          player
        end
      end)
    end)
  end

  defp update_draw_pile(table, updated_draw_pile) do
    update_in(table.draw_pile, fn _draw_pile -> updated_draw_pile end)
  end

  defp update_discard_pile(table, updated_discard_pile) do
    update_in(table.discard_pile, fn _discard_pile -> updated_discard_pile end)
  end

  defp update_players(table, updated_players) do
    update_in(table.players, fn _players -> updated_players end)
  end

  defp place_queen_on_board_at_location(table, queen_card, queen_coordinate) do
    update_in(table.queens_board, fn queens_board ->
      Map.replace(queens_board, queen_coordinate, queen_card)
    end)
  end
end
