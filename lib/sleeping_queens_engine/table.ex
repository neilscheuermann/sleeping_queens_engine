defmodule SleepingQueensEngine.Table do
  alias __MODULE__
  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.QueensBoard

  @enforce_keys [:draw_pile, :discard_pile, :queens_board, :players]
  defstruct [:draw_pile, :discard_pile, :queens_board, :players]

  def new(players) do
    %Table{
      draw_pile: Card.draw_pile_shuffled(),
      discard_pile: [],
      queens_board: QueensBoard.new(),
      players: players
    }
  end

  # TODO>>>> Refactor this function
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
                    Player.pick_up_card(player, top_card)
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

  def select_queen(table, {_, _} = coordinate, player_position) do
    case QueensBoard.take_queen(table.queens_board, coordinate) do
      {%QueenCard{} = selected_queen, updated_queens_board} ->
        updated_table =
          table
          |> update_queens_board(updated_queens_board)
          |> update_players_with_new_queen(selected_queen, player_position)

        {:ok, updated_table}

      {nil, _updated_queens_board} ->
        {:error, :no_queen_in_that_position}

      {:error, error} -> 
        {:error, error}
    end
  end

  ###
  # Private Functions
  #

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
        Player.pick_up_queen(player, queen)
      else
        player
      end
    end)
  end

  defp update_players_with_new_queen(table, selected_queen, player_position) do
    update_in(table, [Access.key!(:players)], fn players ->
      give_player_queen(players, selected_queen, player_position)
    end)
  end

  defp update_queens_board(table, updated_queens_board) do
    update_in(table, [Access.key!(:queens_board)], fn _queens_board ->
      updated_queens_board
    end)
  end
end
