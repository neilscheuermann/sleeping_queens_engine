defmodule SleepingQueensEngine.Player do
  alias SleepingQueensEngine.QueenCard
  alias __MODULE__
  alias SleepingQueensEngine.Card

  @type t() :: %__MODULE__{
          hand: list(),
          name: String.t(),
          position: pos_integer(),
          queens: list()
        }
  @enforce_keys [:hand, :name, :position, :queens]
  defstruct [:hand, :name, :position, :queens]

  @type card_positions() :: [pos_integer()]

  @available_card_positions [1, 2, 3, 4, 5]

  @spec new(String.t(), pos_integer()) :: Player.t()
  def new(name, position) when is_binary(name) and is_integer(position) do
    %Player{
      hand: [],
      name: name,
      position: position,
      queens: []
    }
  end

  @spec select_cards(Player.t(), card_positions()) ::
          {[Card.t()], Player.t()}
  def select_cards(player, card_positions) do
    unselected_card_positions = @available_card_positions -- card_positions

    selected_cards = take_cards(player.hand, card_positions)
    remaining_cards = take_cards(player.hand, unselected_card_positions)

    {selected_cards, update_hand(player, remaining_cards)}
  end

  @spec pick_up_card(Player.t(), Card.t()) :: Player.t()
  def pick_up_card(player, card) when length(player.hand) <= 5 do
    Map.put(player, :hand, [card | player.hand])
  end

  @spec pick_up_queen(Player.t(), QueenCard.t()) :: Player.t()
  def pick_up_queen(player, queen) do
    update_in(player.queens, fn queens -> [queen | queens] end)
  end

  @spec lose_queen(Player.t(), non_neg_integer()) ::
          {Player.t(), QueenCard.t()}
  def lose_queen(player, queen_index) do
    stolen_queen = Enum.at(player.queens, queen_index)
    updated_player = update_in(player.queens, &List.delete_at(&1, queen_index))

    {updated_player, stolen_queen}
  end

  ###
  # Private Functions
  #

  defp take_cards(hand, card_positions) do
    hand
    |> Enum.with_index()
    |> Enum.filter(fn {_card, idx} ->
      card_position = idx + 1
      card_position in card_positions
    end)
    |> Enum.map(fn {card, _i} -> card end)
  end

  defp update_hand(player, new_hand), do: Map.put(player, :hand, new_hand)
end
