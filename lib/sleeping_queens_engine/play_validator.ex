defmodule SleepingQueensEngine.PlayValidator do
  @moduledoc """
  Determines if plays are valid
  """

  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  @type card_positions() :: [pos_integer()]
  @type player_position() :: pos_integer()
  @type waiting_on_action() ::
          :select_queen
          | :draw_for_jester
          | :block_steal_queen
          | :block_place_queen_back_on_board
  @type waiting_on() :: %{
          player_position: player_position(),
          action: waiting_on_action()
        }
  @type next_action() :: nil | waiting_on()

  @doc """
  Can a player play or discard a chosen set of cards based on the current state of the game?
  If so, what's the next required action (if any) before player ends turn?
  """
  @spec check(
          :play | :discard,
          player_position(),
          card_positions(),
          Rules.t(),
          Table.t()
        ) ::
          {:ok, next_action()} | :error
  # Check if player can protect queen from being stolen or placed back on the board
  def check(
        :play,
        player_position,
        card_positions,
        %Rules{
          state: :playing,
          waiting_on: %{
            player_position: waiting_player_position,
            action: waiting_action
          }
        },
        table
      )
      when player_position == waiting_player_position and
             waiting_action in [
               :block_steal_queen,
               :block_place_queen_back_on_board
             ] and
             length(card_positions) == 1 do
    [selected_card] = view_cards(table, player_position, card_positions)

    if can_protect_queen?(waiting_action, selected_card) do
      {:ok, nil}
    else
      :error
    end
  end

  # TODO>>>> Finish
  # def check(
  #       :play,
  #       player_position,
  #       card_positions,
  #       %Rules{
  #         state: :playing,
  #         player_turn: player_turn,
  #         waiting_on: nil
  #       },
  #       table
  #     )
  #     when player_position == player_turn do
  #   cards = view_cards(table, player_position, card_positions)
  #
  #   cond do
  #     cards == [%Card{type: :king}] ->
  #       {:ok, get_next_waiting_on(cards, player_position)}
  #   end
  # end

  def check(_action, _player_position, _card_positions, _rules, _table),
    do: :error

  ###
  # Private Functions
  #

  defp view_cards(table, player_position, card_positions) do
    {cards, _player} =
      table
      |> Table.get_player(player_position)
      |> Player.select_cards(card_positions)

    cards
  end

  defp can_protect_queen?(:block_steal_queen, %Card{type: :dragon}), do: true

  defp can_protect_queen?(:block_place_queen_back_on_board, %Card{type: :wand}),
    do: true

  defp can_protect_queen?(_waiting_action, _card), do: false

  defp get_next_waiting_on(cards, player_position) do
    # TODO>>>> update hardcoded value
    opponent_position = 0

    case cards do
      [%Card{type: :king}] ->
        %{player_position: player_position, action: :select_queen}

      [%Card{type: :jester}] ->
        %{player_position: player_position, action: :draw_for_jester}

      [%Card{type: :knight}] ->
        %{player_position: opponent_position, action: :block_steal_queen}

      [%Card{type: :sleeping_potion}] ->
        %{
          player_position: opponent_position,
          action: :block_place_queen_back_on_board
        }
    end
  end
end
