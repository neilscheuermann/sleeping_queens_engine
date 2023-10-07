defmodule TableTest do
  use ExUnit.Case

  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.Table
  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player

  @expected_draw_pile_size 68
  @max_cards_allowed_in_hand 5
  @player1_position 1
  @player2_position 2
  @queen_position 1
  @queen_coordinate {1, 1}
  @invalid_queen_coordinate {10, 10}
  @invalid_queen_position 20

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

      player1 = Enum.at(players, 0)
      player2 = Enum.at(players, 1)

      assert player1.position == 1
      assert player2.position == 2
    end
  end

  describe "deal_cards/1" do
    test "returns an updated table, having dealt cards from the draw pile to players until they each have 5 cards" do
      table = Table.new([Player.new("Ron"), Player.new("Leslie")])
      player1 = Enum.find(table.players, &(&1.position == 1))
      player2 = Enum.find(table.players, &(&1.position == 2))

      assert player1.hand == []
      assert player2.hand == []
      assert length(table.draw_pile) == @expected_draw_pile_size

      updated_table = Table.deal_cards(table)

      updated_player1 = Enum.find(updated_table.players, &(&1.position == 1))
      updated_player2 = Enum.find(updated_table.players, &(&1.position == 2))

      assert length(updated_player1.hand) == @max_cards_allowed_in_hand
      assert length(updated_player2.hand) == @max_cards_allowed_in_hand

      assert length(updated_table.draw_pile) ==
               @expected_draw_pile_size -
                 length(table.players) * @max_cards_allowed_in_hand
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

    test "success: returns an updated table, having discarded the player's selected card(s)",
         %{table: table} do
      card_positions = [1]

      assert {:ok, updated_table} =
               Table.discard_cards(table, card_positions, @player1_position)

      updated_player1 =
        Enum.find(updated_table.players, &(&1.position == @player1_position))

      assert length(updated_player1.hand) ==
               @max_cards_allowed_in_hand - length(card_positions)

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

    test "success: returns an updated table, having moved selected queen from board to player's queens pile",
         %{table: table} do
      assert %QueenCard{} = table.queens_board[@queen_coordinate]
      assert Enum.all?(table.players, &(&1.queens == []))

      assert {:ok, updated_table} =
               Table.select_queen(table, @queen_coordinate, @player1_position)

      updated_player1 =
        Enum.find(updated_table.players, &(&1.position == @player1_position))

      refute updated_table.queens_board[@queen_coordinate]
      assert [%QueenCard{}] = updated_player1.queens
    end

    test "error: returns error if no queen at valid coordinate",
         %{table: table} do
      assert {:ok, updated_table} =
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
      {:ok, table} =
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
      {:ok, table} =
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

  ###
  # Private Functions
  #

  defp get_player(table, player_position),
    do: Enum.find(table.players, &(&1.position == player_position))

  defp get_queen(player, queen_position),
    do: Enum.at(player.queens, queen_position - 1)
end
