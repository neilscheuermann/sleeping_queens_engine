defmodule SleepingQueensEngine.QueenCard do
  alias SleepingQueensEngine.QueenCoordinate
  alias __MODULE__

  @type t() :: %__MODULE__{
          name: String.t(),
          value: pos_integer(),
          special?: boolean(),
          # TODO>>>> Maybe remove?
          coordinate: QueenCoordinate.t()
        }
  @enforce_keys [:name, :value, :special?]
  defstruct [:name, :value, :special?, :coordinate]

  @special_queen_names ~w(rose strawberry cat dog)

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

  @spec queens_pile_shuffled() :: [QueenCard.t()]
  def queens_pile_shuffled() do
    for %{name: name, value: value} <- @queens do
      %QueenCard{
        name: name,
        value: value,
        special?: is_special?(name)
      }
    end
    |> Enum.shuffle()
  end

  ###
  # Private Functions
  #

  defp is_special?(name) when name in @special_queen_names, do: true
  defp is_special?(_name), do: false
end
