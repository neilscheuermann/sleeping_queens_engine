defmodule SleepingQueensEngine.Card do
  alias __MODULE__

  @enforce_keys [:type]
  defstruct [:type, :name, :value]

  @kings ~w(name1 name2 name3 name4 name5 name6 name7 name8 name9 name10)a

  def draw_pile_shuffled() do
    cards =
      kings() ++
        jesters() ++
        knights() ++
        dragons() ++
        sleeping_potions() ++
        wands() ++
        numbers()

    shuffle(cards)
  end

  def shuffle(cards), do: Enum.shuffle(cards)

  ###
  # Private Functions
  #

  defp kings() do
    for king <- @kings do
      %Card{
        type: :king,
        name: king
      }
    end
  end

  defp numbers() do
    for _ <- 1..4, value <- 1..10 do
      %Card{
        type: :number,
        value: value
      }
    end
  end

  defp jesters(), do: for(_ <- 1..4, do: %Card{type: :jester})
  defp knights(), do: for(_ <- 1..4, do: %Card{type: :knight})
  defp sleeping_potions(), do: for(_ <- 1..4, do: %Card{type: :sleeping_potion})
  defp dragons(), do: for(_ <- 1..3, do: %Card{type: :dragon})
  defp wands(), do: for(_ <- 1..3, do: %Card{type: :wand})
end
