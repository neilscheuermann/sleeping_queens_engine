defmodule SleepingQueensEngine.Table do
  alias __MODULE__
  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.QueensBoard
  alias SleepingQueensEngine.Rules

  @max_allowed_players 5
  @max_allowed_cards_in_hand 5

  @type t() :: %__MODULE__{
          draw_pile: list(),
          discard_pile: list(),
          queens_board: map(),
          players: list()
        }
  @enforce_keys [:draw_pile, :discard_pile, :queens_board, :players]
  defstruct [:draw_pile, :discard_pile, :queens_board, :players]

  @type card_positions() :: [pos_integer()]
  @type player_position() :: pos_integer()
  @type player_queen_position() :: pos_integer()
  @type queen_coordinate() :: {pos_integer(), pos_integer()}
  @type discard_error() :: :invalid_card_selections
  @type select_queen_error() ::
          :no_queen_at_that_position | :invalid_coordinate
  @type steal_queen_error() ::
          :queen_exists_at_coordinate | :invalid_coordinate
  @type steal_queen_params() :: %{
          opponent_player_position: player_position(),
          opponent_queen_position: player_queen_position(),
          queen_coordinate: queen_coordinate() | nil,
          stealing_player_position: player_position() | nil
        }
  @type waiting_on() :: %{
          player_position: player_position(),
          action: :select_queen
        }

  defguard selected_enough_cards?(card_positions)
           when length(card_positions) > 0 and length(card_positions) <= 5

  @doc """
  Given a list of players it creates a new Table holding needed game entities
  ## Example
    iex> alias SleepingQueensEngine.{Table, Player}
    iex> players = [Player.new("Ron")]
    iex> table = Table.new(players)
    iex> %Table{discard_pile: _, draw_pile: _, players: _, queens_board: _} 
    ...>   = table
  """
  @spec new([Player.t()]) :: Table.t()
  def new(players) do
    players = assign_player_positions(players)

    %Table{
      discard_pile: [],
      draw_pile: Card.draw_pile_shuffled(),
      players: players,
      queens_board: QueensBoard.new()
    }
  end

  @spec add_player(Table.t(), Player.t()) :: Table.t()
  def add_player(table, %Player{} = player)
      when length(table.players) < @max_allowed_players do
    next_available = length(table.players) + 1
    player = Map.replace(player, :position, next_available)

    {:ok, update_in(table.players, fn players -> [player | players] end)}
  end

  def add_player(_table, %Player{} = _player) do
    {:error, :max_allowed_players_reached}
  end

  @spec get_player(Table.t(), player_position()) :: Player.t()
  def get_player(table, player_position),
    do: Enum.find(table.players, &(&1.position == player_position))

  @spec deal_cards(Table.t(), player_position()) :: Table.t()
  def deal_cards(table, starting_player_position \\ 1) do
    # TODO::: find a better way to loop through players until each has 5 cards
    Enum.reduce_while(
      1..1_000,
      {table, starting_player_position},
      fn _num, {table_acc, player_position_to_deal} ->
        %{draw_pile: draw_pile, players: players} = table_acc

        if all_players_dealt?(players) do
          {:halt, table_acc}
        else
          [top_card | remaining_draw_pile] = draw_pile

          player_needing_card =
            Table.get_player(table_acc, player_position_to_deal)

          players = give_card_to_player(players, top_card, player_needing_card)

          updated_table_acc =
            table_acc
            |> update_players(players)
            |> update_draw_pile(remaining_draw_pile)

          {:cont,
           {updated_table_acc,
            get_next_player_position(updated_table_acc, player_position_to_deal)}}
        end
      end
    )
  end

  @spec discard_cards(Table.t(), card_positions(), player_position()) ::
          {:ok, Table.t()} | {:error, discard_error()}
  def discard_cards(table, card_positions, player_position)
      when selected_enough_cards?(card_positions) do
    {cards_to_play, updated_player} =
      table
      |> get_player(player_position)
      |> Player.select_cards(card_positions)

    updated_table =
      table
      |> update_player(updated_player)
      |> add_to_discard_pile(cards_to_play)

    {:ok, updated_table}
  end

  def discard_cards(_table, _card_positions, _player_position) do
    {:error, :invalid_card_selections}
  end

  @spec select_queen(Table.t(), queen_coordinate(), player_position()) ::
          {:ok, Table.t()} | {:error, select_queen_error()}
  def select_queen(table, {_, _} = coordinate, player_position) do
    case QueensBoard.take_queen(table.queens_board, coordinate) do
      {%QueenCard{} = selected_queen, updated_queens_board} ->
        updated_table =
          table
          |> update_queens_board(updated_queens_board)
          |> update_players_with_new_queen(selected_queen, player_position)

        {:ok, updated_table}

      {nil, _updated_queens_board} ->
        {:error, :no_queen_at_that_position}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec place_queen_on_board(
          Table.t(),
          player_position(),
          player_queen_position(),
          queen_coordinate()
        ) ::
          {:ok, Table.t()} | {:error, steal_queen_error()}
  def place_queen_on_board(
        table,
        player_position,
        queen_position,
        queen_coordinate
      ) do
    player = get_player(table, player_position)

    with {:ok, {updated_player, queen}} <-
           Player.lose_queen(player, queen_position),
         {:ok, updated_queens_board} <-
           QueensBoard.place_queen(table.queens_board, queen_coordinate, queen) do
      updated_table =
        table
        |> update_queens_board(updated_queens_board)
        |> update_player(updated_player)

      {:ok, updated_table}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec steal_queen(
          Table.t(),
          player_position(),
          player_queen_position(),
          player_position()
        ) ::
          {:ok, Table.t()} | {:error, steal_queen_error()}
  def steal_queen(
        table,
        opponent_player_position,
        opponent_queen_position,
        stealing_player_position
      ) do
    opponent = get_player(table, opponent_player_position)
    player = get_player(table, stealing_player_position)

    with {:ok, {updated_opponent, queen}} <-
           Player.lose_queen(opponent, opponent_queen_position),
         updated_player <-
           Player.add_queen(player, queen) do
      updated_table =
        table
        |> update_player(updated_opponent)
        |> update_player(updated_player)

      {:ok, updated_table}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Player draws the top card after jester is played. This returns an updated table
  with the correct next waiting_on.

  When the top card is an action card the card is placed in the player's hand and
  they can take another turn. No next waiting_on.

  When the top card is a number the card is discarded and count off the number
  of the players to the left, starting with the player who drew the jester. The 
  next waiting_on should indicate this player to select a queen.
  """
  @spec draw_for_jester(Table.t(), Rules.t(), player_position()) ::
          {:ok, Table.t(), nil | waiting_on()} | :error
  def draw_for_jester(
        table,
        %{
          waiting_on: %{
            action: :draw_for_jester,
            player_position: waiting_player_position
          }
        } = rules,
        player_position
      )
      when waiting_player_position == player_position do
    [top_card | remaining_draw_pile] = table.draw_pile

    updated_table =
      table
      |> update_draw_pile(remaining_draw_pile)
      |> maybe_update_discard_pile(top_card)
      |> maybe_update_players_hand(top_card, player_position)

    waiting_on = determine_next_waiting_on(rules, top_card)

    {:ok, updated_table, waiting_on}
  end

  def draw_for_jester(_table, _waiting_on, _player_position) do
    :error
  end

  @doc """
  Given a player's position, it tells if any others have a queen.
  """
  @spec others_have_a_queen?(Table.t(), player_position()) :: boolean()
  def others_have_a_queen?(table, player_position) do
    table
    |> Map.get(:players)
    |> Enum.filter(&(&1.position != player_position))
    |> Enum.any?(fn
      %{queens: [_ | _]} -> true
      _ -> false
    end)
  end

  ###
  # Private Functions
  #

  defp add_to_discard_pile(table, cards) do
    update_in(table.discard_pile, fn discard_pile ->
      cards ++ discard_pile
    end)
  end

  defp assign_player_positions(players) do
    players
    |> Enum.with_index()
    |> Enum.map(fn {player, index} ->
      Map.replace(player, :position, index + 1)
    end)
  end

  defp update_player(table, updated_player) do
    update_in(table.players, fn players ->
      do_update_player(players, updated_player)
    end)
  end

  # TODO::: Change players from a list to a map with player position for keys.
  # Then I could replace with a Map.replace, rather than this Enum map.
  defp do_update_player(players, updated_player) do
    Enum.map(players, fn player ->
      if player.position == updated_player.position do
        updated_player
      else
        player
      end
    end)
  end

  defp all_players_dealt?(players) do
    Enum.all?(players, fn player ->
      length(player.hand) == 5
    end)
  end

  defp find_players_needing_cards(table) do
    Enum.filter(
      table.players,
      &(length(&1.hand) < @max_allowed_cards_in_hand)
    )
  end

  defp get_next_player_position(table, player_position_just_dealt) do
    players_needing_cards = find_players_needing_cards(table)

    if next_higher_player =
         Enum.find(
           players_needing_cards,
           &(&1.position > player_position_just_dealt)
         ) do
      next_higher_player.position
    else
      players_needing_cards
      |> List.first(%{})
      |> Map.get(:position)
    end
  end

  defp give_player_queen(players, %QueenCard{} = queen, player_position) do
    Enum.map(players, fn player ->
      if player.position == player_position do
        Player.add_queen(player, queen)
      else
        player
      end
    end)
  end

  defp give_card_to_player(players, card, player_needing_card) do
    Enum.map(players, fn player ->
      if player.name == player_needing_card.name and
           length(player_needing_card.hand) < @max_allowed_cards_in_hand do
        Player.add_cards_to_hand(player, [card])
      else
        player
      end
    end)
  end

  defp update_draw_pile(table, updated_draw_pile) do
    update_in(table.draw_pile, fn _draw_pile -> updated_draw_pile end)
  end

  # TODO::: Just pass in the updated  queen to this function
  defp update_players_with_new_queen(table, selected_queen, player_position) do
    update_in(table.players, fn players ->
      give_player_queen(players, selected_queen, player_position)
    end)
  end

  defp update_players(table, updated_players) do
    update_in(table.players, fn _players -> updated_players end)
  end

  defp update_queens_board(table, updated_queens_board) do
    update_in(table.queens_board, fn _queens_board -> updated_queens_board end)
  end

  defp maybe_update_discard_pile(table, card_from_jester) do
    update_in(table.discard_pile, fn discard_pile ->
      if card_from_jester.type == :number do
        [card_from_jester | discard_pile]
      else
        discard_pile
      end
    end)
  end

  defp maybe_update_players_hand(table, card_from_jester, player_position) do
    update_in(table.players, fn players ->
      Enum.map(players, fn player ->
        if player.position == player_position and
             card_from_jester.type != :number do
          update_in(player.hand, fn hand
                                    when length(hand) <
                                           @max_allowed_cards_in_hand ->
            [card_from_jester | hand]
          end)
        else
          player
        end
      end)
    end)
  end

  defp determine_next_waiting_on(rules, card_from_jester) do
    if card_from_jester.type == :number do
      %{
        action: :select_queen,
        player_position:
          count_players_to_select_queen(rules, card_from_jester.value)
      }
    else
      nil
    end
  end

  defp count_players_to_select_queen(rules, positions_to_count) do
    Enum.reduce(1..positions_to_count, rules.player_turn, fn count, acc ->
      cond do
        # the first count starts on the player whose turn it is
        count == 1 -> acc
        # then start counting left, starting over at player one after counting last player
        acc < rules.player_count -> acc + 1
        true -> 1
      end
    end)
  end
end
