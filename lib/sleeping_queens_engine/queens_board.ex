defmodule SleepingQueensEngine.QueensBoard do
  alias SleepingQueensEngine.QueenCard

  defguard is_valid_coordinate(row, col)
           when row >= 1 and row <= 4 and col >= 1 and col <= 4

  def new() do
    queens = QueenCard.queens_pile_shuffled()

    {board_map, _} =
      Enum.reduce(
        coordinates(),
        {%{}, queens},
        fn coordinate, {board_map, [queen | remaining_queens]} ->
          {Map.put(board_map, coordinate, queen), remaining_queens}
        end
      )

    board_map
  end

  def take_queen(queens_board, {row, col} = coordinate)
      when is_valid_coordinate(row, col) do
    Map.get_and_update!(queens_board, coordinate, fn queen ->
      {queen, nil}
    end)
  end

  def take_queen(_queens_board, _coordinate) do
    {:error, :invalid_position}
  end

  def get(board, row, col) do
    board[{row, col}]
  end

  def set(board, row, col, queen) do
    Map.put(board, {row, col}, queen)
  end

  ###
  # Private Functions
  #

  # Returns coordinate tuples for 4x4 board 
  # ex: [{1,1}, {1,2}, ..., {4,3}, {4,4}]
  defp coordinates() do
    for row <- 1..4, col <- 1..4 do
      {row, col}
    end
  end
end
