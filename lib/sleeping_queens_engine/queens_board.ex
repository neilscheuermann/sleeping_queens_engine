defmodule SleepingQueensEngine.QueensBoard do
  alias SleepingQueensEngine.QueenCard

  defguard is_valid_coordinate(row, col)
           when row >= 1 and row <= 4 and col >= 1 and col <= 4

  @empty_queens_board %{
    {1, 1} => nil,
    {1, 2} => nil,
    {1, 3} => nil,
    {1, 4} => nil,
    {2, 1} => nil,
    {2, 2} => nil,
    {2, 3} => nil,
    {2, 4} => nil,
    {3, 1} => nil,
    {3, 2} => nil,
    {3, 3} => nil,
    {3, 4} => nil,
    {4, 1} => nil,
    {4, 2} => nil,
    {4, 3} => nil,
    {4, 4} => nil
  }

  @type queens_board_coordinate() :: {pos_integer(), pos_integer()}
  @type queens_board() :: %{queens_board_coordinate() => QueenCard | nil}
  @type place_queen_error() ::
          :invalid_coordinate | :queen_exists_at_coordinate

  @spec empty() :: queens_board()
  def empty(), do: @empty_queens_board

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

  @spec place_queen(queens_board(), queens_board_coordinate(), QueenCard.t()) ::
          {:ok, queens_board()} | {:error, place_queen_error()}
  def place_queen(queens_board, {row, col} = coordinate, queen)
      when is_valid_coordinate(row, col) do
    case Map.get(queens_board, coordinate) do
      %QueenCard{} -> {:error, :queen_exists_at_coordinate}
      nil -> {:ok, Map.replace!(queens_board, coordinate, queen)}
    end
  end

  def place_queen(_queens_board, _coordinate, _queen) do
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
