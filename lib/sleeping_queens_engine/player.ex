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

  def pick_up_queen(player, queen) do
    update_in(player.queens, fn queens -> [queen | queens] end)
  end

  def lose_queen(player, queen_index) do
    stolen_queen = Enum.at(player.queens, queen_index)
    updated_player = update_in(player.queens, &List.delete_at(&1, queen_index))

    {updated_player, stolen_queen}
  end
end
