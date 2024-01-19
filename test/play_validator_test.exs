defmodule PlayValidatorTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.PlayValidator
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  # when it's the waiting player's turn (ex: dragon or wand to protect a queen)
  describe "check/4 :play" do
    setup do
      player = Player.new("Ron")
      opponent = Player.new("Leslie")

      table = Table.new([player, opponent])

      rules =
        Rules.new()
        |> Map.replace(:state, :playing)
        |> Map.replace(:player_count, 2)

      %{
        player: Table.get_player(table, 1),
        opponent: Table.get_player(table, 2),
        rules: rules,
        table: table
      }
    end

    # TODO>>>> Use tags and private setup functions.
    # @tag player_turn: :opponent, waiting_on_player: :player, waiting_on_action: :block_place_queen_back_on_board, cards_in_player_hand: [:dragon]
    test "returns success with no next move when cheking a dragon to protect a queen from being stolen",
         %{
           player: player,
           opponent: opponent,
           rules: rules,
           table: table
         } do
      dragon_card = %Card{type: :dragon}

      rules =
        rules
        |> Map.replace(:player_turn, opponent.position)
        |> Map.replace(:waiting_on, %{
          player_position: player.position,
          action: :block_place_queen_back_on_board
        })

      table = add_cards_to_players_hand(table, [dragon_card], player.position)

      dragon_card_position = 1

      assert {:ok, nil = _waiting_on} =
               PlayValidator.check(
                 :play,
                 player.position,
                 [dragon_card_position],
                 rules,
                 table
               )
    end

    # TODO>>>> Finish this after refactoring the setup 👇
    # test "successfully returns nil for waiting_on when playing a wand to protect queen from being placed back on the board",
    #      %{
    #        rules: rules
    #      } do
    # end
    #
    # test "errors when playing any other card", %{
    #   rules: rules
    # } do
    # end
  end

  # TODO>>>> Finish all these 👇👇👇
  # when it's the player's turn (ex: king, jester, knight, or sleeping potion)
  describe "check/4 :play, " do
    #   setup do
    #     rules =
    #       Rules.new()
    #       |> Map.replace(:state, :playing)
    #       |> Map.replace(:player_count, 2)
    #
    #     %{rules: rules}
    #   end
    #
    #   test "successfully prompts current player to select queen when playing a king",
    #        %{
    #          rules: rules
    #        } do
    #   end
    #
    #   test "successfully prompts current player to select a card for jester when playing a jester",
    #        %{
    #          rules: rules
    #        } do
    #   end
    #
    #   test "successfully prompts opposing player to protect their queen when playing a knight",
    #        %{
    #          rules: rules
    #        } do
    #   end
    #
    #   test "successfully prompts opposing player to protect their queen when playing a sleeping potion",
    #        %{
    #          rules: rules
    #        } do
    #   end
    # end
    #
    # describe "check/4 :discard, when it's the player's turn," do
    #   setup do
    #     rules =
    #       Rules.new()
    #       |> Map.replace(:state, :playing)
    #       |> Map.replace(:player_count, 2)
    #
    #     %{rules: rules}
    #   end
    #
    #   test "successfully returns nil for waiting_on when discarding a single card of any type",
    #        %{
    #          rules: rules
    #        } do
    #   end
    #
    #   test "successfully returns nil for waiting_on when discarding 2 matching numbers",
    #        %{
    #          rules: rules
    #        } do
    #   end
    #
    #   test "successfully returns nil for waiting_on when discarding 3 or more numbers that make a valid addition equation",
    #        %{
    #          rules: rules
    #        } do
    #   end
    #
    #   test "errors when trying to discard 2 matching non-numbers", %{
    #     rules: rules
    #   } do
    #   end
  end

  ###
  # Private Functions
  #

  # TODO>>>> Add this as a function to Table? Can be used in deal function refactor?
  defp add_cards_to_players_hand(table, cards, player_position) do
    update_in(table.players, fn players ->
      give_player_cards(players, player_position, cards)
    end)
  end

  defp give_player_cards(players, player_position, cards) do
    Enum.map(players, fn player ->
      if player.position == player_position do
        Player.add_cards_to_hand(player, cards)
      else
        player
      end
    end)
  end
end
