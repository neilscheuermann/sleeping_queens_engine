defmodule SleepingQueensEngine.Table do
  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.QueensBoard
  alias __MODULE__

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

  ###
  # Private Functions
  #

  defp all_players_dealt?(players) do
    Enum.all?(players, fn player ->
      length(player.hand) == 5
    end)
  end

  def find_player_needing_card(players) do
    Enum.find(players, fn player ->
      length(player.hand) < 5
    end)
  end
end
