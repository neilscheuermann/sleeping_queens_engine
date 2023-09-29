defmodule SleepingQueensEngine.Player do
  alias __MODULE__

  @enforce_keys [:hand, :name, :position, :queens]
  defstruct [:hand, :name, :position, :queens]

  def new(name, position) when is_binary(name) and is_integer(position) do
    %Player{
      hand: [],
      name: name,
      position: position,
      queens: []
    }
  end

  def pick_up_card(player, card) when length(player.hand) <= 5 do
    Map.put(player, :hand, [card | player.hand])
  end
end
