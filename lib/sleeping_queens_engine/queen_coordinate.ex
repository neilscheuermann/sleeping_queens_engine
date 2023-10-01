defmodule SleepingQueensEngine.QueenCoordinate do
  alias __MODULE__
  # Must define before `defstruct` to have an effect 
  @type t() :: %__MODULE__{
          col: pos_integer(),
          row: pos_integer()
        }
  @enforce_keys [:row, :col]
  defstruct [:row, :col]

  @board_range 1..4

  def new(row, col) when row in @board_range and col in @board_range do
    {:ok, %QueenCoordinate{row: row, col: col}}
  end

  def new(_row, _col), do: {:error, :invalid_queen_coordinate}
end
