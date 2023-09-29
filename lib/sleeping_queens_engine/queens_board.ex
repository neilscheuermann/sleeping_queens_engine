defmodule SleepingQueensEngine.QueensBoard do
  alias SleepingQueensEngine.QueenCard

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
