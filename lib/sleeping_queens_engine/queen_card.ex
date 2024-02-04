defmodule SleepingQueensEngine.QueenCard do
  alias __MODULE__

  @type t() :: %__MODULE__{
          name: String.t(),
          value: pos_integer(),
          special?: boolean(),
        }
  @enforce_keys [:name, :value, :special?]
  defstruct [:name, :value, :special?, :coordinate]

  @special_queen_names ~w(rose strawberry cat dog)

  @queens [
    %{name: "book", value: 15},
    %{name: "butterfly", value: 10},
    %{name: "cake", value: 5},
    %{name: "cat", value: 15},
    %{name: "dog", value: 15},
    %{name: "heart", value: 20},
    %{name: "ice cream", value: 5},
    %{name: "ladybug", value: 10},
    %{name: "moon", value: 10},
    %{name: "pancake", value: 15},
    %{name: "peacock", value: 10},
    %{name: "rainbow", value: 5},
    %{name: "rose", value: 5},
    %{name: "starfish", value: 5},
    %{name: "strawberry", value: 10},
    %{name: "sunflower", value: 10}
  ]

  def new(name, value),
    do: %QueenCard{
      name: name,
      value: value,
      special?: is_special?(name)
    }

  @spec queens_pile_shuffled() :: [QueenCard.t()]
  def queens_pile_shuffled() do
    for %{name: name, value: value} <- @queens do
      new(name, value)
    end
    |> Enum.shuffle()
  end

  ###
  # Private Functions
  #

  defp is_special?(name) when name in @special_queen_names, do: true
  defp is_special?(_name), do: false
end
