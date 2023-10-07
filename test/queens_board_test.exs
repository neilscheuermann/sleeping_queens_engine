defmodule QueensBoardTest do
  use ExUnit.Case

  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.QueensBoard

  @expected_queens_board_coordinates [
    {1, 1},
    {1, 2},
    {1, 3},
    {1, 4},
    {2, 1},
    {2, 2},
    {2, 3},
    {2, 4},
    {3, 1},
    {3, 2},
    {3, 3},
    {3, 4},
    {4, 1},
    {4, 2},
    {4, 3},
    {4, 4}
  ]
  @take_queen_error_msg :invalid_coordinate

  describe "new/0" do
    test "returns a queens board with expected coordinate keys and queen values" do
      queens_board = QueensBoard.new()
      expected_queens = QueenCard.queens_pile_shuffled()

      for {coordinate, queen} <- Map.to_list(queens_board) do
        assert coordinate in @expected_queens_board_coordinates
        assert queen in expected_queens
      end
    end
  end

  describe "take_queen/2" do
    test "returns the queen from provided coordinate along with updated queens_board" do
      queens_board = QueensBoard.new()
      valid_coordinate = {1, 1}

      assert {%QueenCard{}, updated_queens_board} =
               QueensBoard.take_queen(queens_board, valid_coordinate)

      refute updated_queens_board[valid_coordinate]
    end

    test "returns nil for queen if there's no queen at that coordinate" do
      queens_board = QueensBoard.new()
      first_coordinate = {1, 1}
      QueensBoard.take_queen(queens_board, first_coordinate)

      # Returns QueenCard the first try
      assert {%QueenCard{}, updated_queens_board} =
               QueensBoard.take_queen(queens_board, first_coordinate)

      refute updated_queens_board[first_coordinate]

      # Returns nil the second try
      assert {nil, updated_queens_board} =
               QueensBoard.take_queen(updated_queens_board, first_coordinate)

      refute updated_queens_board[first_coordinate]
    end

    test "failure: returns error tuple if coordinate is invalid" do
      queens_board = QueensBoard.new()
      invalid_coordinate = {10, 10}

      assert {:error, @take_queen_error_msg} =
               QueensBoard.take_queen(queens_board, invalid_coordinate)
    end
  end

  describe "place_queen/2" do
    test "successfully returns the updated queens_board with the queen card placed in the provided coordinate" do
      queens_board = QueensBoard.new()
      coordinate = {1, 1}
      {queen, queens_board} = QueensBoard.take_queen(queens_board, coordinate)

      assert is_nil(queens_board[coordinate])

      assert {:ok, queens_board} =
               QueensBoard.place_queen(queens_board, coordinate, queen)

      assert queens_board[coordinate] == queen
    end

    test "errors if the coordinate is already occupied by another queen" do
      queens_board = QueensBoard.new()
      coordinate = {1, 1}
      queen = QueenCard.new("rose", 5)

      assert {:error, :queen_exists_at_coordinate} =
               QueensBoard.place_queen(queens_board, coordinate, queen)
    end

    test "errors if the coordinate is invalid" do
      queens_board = QueensBoard.new()
      invalide_coordinate = {10, 10}
      queen = QueenCard.new("rose", 5)

      assert {:error, :invalid_coordinate} =
               QueensBoard.place_queen(queens_board, invalide_coordinate, queen)
    end
  end
end
