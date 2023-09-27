defmodule SleepingQueensEngine.QueenCard do
  alias SleepingQueensEngine.QueenCoordinate
  alias __MODULE__

  @enforce_keys [:name, :value, :special?]
  defstruct [:name, :value, :special?, :coordinate]

  @special_queens ~w(rose strawberry cat dog)

  @queens [
    %{name: "rose", value: 5},
    %{name: "strawberry", value: 10},
    %{name: "cat", value: 15},
    %{name: "dog", value: 15},
    %{name: "name1", value: 5},
    %{name: "name2", value: 5},
    %{name: "name3", value: 5},
    %{name: "name4", value: 10},
    %{name: "name5", value: 10},
    %{name: "name6", value: 10},
    %{name: "name7", value: 10},
    %{name: "name8", value: 10},
    %{name: "name9", value: 15},
    %{name: "name10", value: 15},
    %{name: "name11", value: 15},
    %{name: "name12", value: 15}
  ]

  def queens_pile() do
    for %{name: name, value: value} <- @queens do
      %QueenCard{
        name: name,
        value: value,
        special?: is_special?(name)
      }
    end
  end

  def place_queen(%QueenCard{} = queen, %QueenCoordinate{} = coordinate) do
    Map.put(queen, :coordinate, coordinate)
  end

  def remove_queen(%QueenCard{} = queen) do
    Map.put(queen, :coordinate, nil)
  end

  ###
  # Private Functions
  #

  defp is_special?(name) when name in @special_queens, do: true
  defp is_special?(_name), do: false
end
