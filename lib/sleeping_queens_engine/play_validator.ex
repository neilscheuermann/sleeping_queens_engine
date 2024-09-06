defmodule SleepingQueensEngine.PlayValidator do
  @moduledoc """
  Determines if plays are valid and determines the next move required
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
          | :steal_queen
          | :place_queen_back_on_board
  @type waiting_on() ::
          %{
            player_position: player_position(),
            action: waiting_on_action()
          }
          | nil

  @doc """
  Checks if a player can play or discard a chosen set of cards based on the 
  current state of the game.
  If so, is returns the next required action (if any) before player ends turn.
  """
  @spec check(
          :play | :discard,
          player_position(),
          card_positions(),
          Rules.t(),
          Table.t()
        ) ::
          {:ok, waiting_on()} | :error
  # When it's waiting on player, check if they can protect queen from being stolen or placed back on the board
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

  # When it's player's turn, checks if they can play offense action card
  def check(
        :play,
        player_position,
        card_positions,
        %Rules{
          state: :playing,
          player_turn: player_turn,
          waiting_on: nil
        },
        table
      )
      when player_position == player_turn and
             length(card_positions) == 1 do
    [card] = view_cards(table, player_position, card_positions)

    if Card.offense_action_card?(card) and
         can_play_offense_action_card?(card, table, player_position) do
      {:ok, determine_next_waiting_on(card, player_position)}
    else
      :error
    end
  end

  # When it's player's turn, check's if they can discard
  def check(
        :discard,
        player_position,
        card_positions,
        %Rules{
          state: :playing,
          player_turn: player_turn,
          waiting_on: nil
        },
        table
      )
      when player_position == player_turn do
    cards = view_cards(table, player_position, card_positions)

    if is_valid_discard?(cards) do
      {:ok, nil}
    else
      :error
    end
  end

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

  defp is_valid_discard?([%Card{}]), do: true

  defp is_valid_discard?([
         %Card{type: :number, value: value1},
         %Card{type: :number, value: value2}
       ])
       when value1 == value2,
       do: true

  defp is_valid_discard?(cards) when length(cards) > 2 do
    if Enum.all?(cards, &(&1.type == :number)) do
      can_make_valid_addition_equation?(cards)
    else
      false
    end
  end

  defp is_valid_discard?(_cards), do: false

  defp can_make_valid_addition_equation?(cards) do
    [largest | remaining] =
      cards
      |> Enum.map(& &1.value)
      |> Enum.sort(:desc)

    largest == Enum.sum(remaining)
  end

  defp determine_next_waiting_on(card, player_position) do
    case card do
      %Card{type: :king} ->
        %{player_position: player_position, action: :select_queen}

      %Card{type: :jester} ->
        %{player_position: player_position, action: :draw_for_jester}

      %Card{type: :knight} ->
        %{player_position: player_position, action: :steal_queen}

      %Card{type: :sleeping_potion} ->
        %{
          player_position: player_position,
          action: :place_queen_back_on_board
        }
    end
  end

  defp can_play_offense_action_card?(
         %Card{type: :king},
         _table,
         _player_position
       ),
       do: true

  defp can_play_offense_action_card?(
         %Card{type: :jester},
         _table,
         _player_position
       ),
       do: true

  defp can_play_offense_action_card?(%Card{type: type}, table, player_position)
       when type in [:knight, :sleeping_potion],
       do: Table.others_have_a_queen?(table, player_position)

  defp can_play_offense_action_card?(_card, _table, _player_position), do: false
end
