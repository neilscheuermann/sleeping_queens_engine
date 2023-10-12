defmodule SleepingQueensEngine.Table do
  alias __MODULE__
  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.QueensBoard

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

  defguard selected_enough_cards?(card_positions)
           when length(card_positions) > 0 and length(card_positions) <= 5

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

  # TODO>>>> Refactor this function
  @spec deal_cards(Table.t()) :: Table.t()
  def deal_cards(table) do
    updated_table =
      Enum.reduce_while(1..length(table.draw_pile), table, fn _num, table_acc ->
        %{draw_pile: draw_pile, players: players} = table_acc
        [top_card | remaining_draw_pile] = draw_pile

        if all_players_dealt?(players) do
          {:halt, table_acc}
        else
          player_needing_card = find_player_needing_card(players)

          updated_table_acc =
            table_acc
            |> update_in(
              [Access.key!(:players)],
              fn players ->
                Enum.map(players, fn player ->
                  if player.name == player_needing_card.name do
                    Player.add_card_to_hand(player, top_card)
                  else
                    player
                  end
                end)
              end
            )
            |> update_in(
              [Access.key!(:draw_pile)],
              fn _draw_pile -> remaining_draw_pile end
            )

          {:cont, updated_table_acc}
        end
      end)

    updated_table
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

  defp get_player(table, player_position),
    do: Enum.find(table.players, &(&1.position == player_position))

  defp update_player(table, updated_player) do
    update_in(table.players, fn players ->
      do_update_player(players, updated_player)
    end)
  end

  # TODO>>> Change players from a list to a map with player position for keys.
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

  defp find_player_needing_card(players) do
    Enum.find(players, fn player ->
      length(player.hand) < 5
    end)
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

  # TODO>>>> Just pass in the updated  queen to this function
  defp update_players_with_new_queen(table, selected_queen, player_position) do
    update_in(table.players, fn players ->
      give_player_queen(players, selected_queen, player_position)
    end)
  end

  defp update_queens_board(table, updated_queens_board) do
    update_in(table.queens_board, fn _queens_board ->
      updated_queens_board
    end)
  end
end
