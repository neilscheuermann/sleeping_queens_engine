defmodule SleepingQueensEngine.QueensBoard do
  alias SleepingQueensEngine.QueenCard

  defguard is_valid_coordinate(row, col)
           when row >= 1 and row <= 4 and col >= 1 and col <= 4

  @type queens_board_coordinate() :: {pos_integer(), pos_integer()}
  @type queens_board() :: %{queens_board_coordinate() => QueenCard | nil}

  @spec new() :: queens_board()
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

  @spec take_queen(queens_board(), queens_board_coordinate()) ::
          {QueenCard.t() | nil, queens_board()} | {:error, :invalid_coordinate}
  def take_queen(queens_board, {row, col} = coordinate)
      when is_valid_coordinate(row, col) do
    Map.get_and_update!(queens_board, coordinate, fn queen ->
      new_value = nil
      {queen, new_value}
    end)
  end

  def take_queen(_queens_board, _coordinate) do
    {:error, :invalid_coordinate}
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
