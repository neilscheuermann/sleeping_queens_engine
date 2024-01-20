defmodule PlayValidatorTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.PlayValidator
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  # when it's waiting on player (ex: have a dragon or wand to protect a queen?)
  describe "check/5 :play" do
    setup [
      :setup_game_table,
      :setup_rules_state,
      :setup_cards_in_player_hand,
      :setup_player_turn,
      :setup_waiting_on
    ]

    @tag player_turn: :opponent,
         waiting_on_player: :player,
         waiting_on_action: :block_steal_queen,
         cards_in_player_hand: [:dragon]
    test "returns success with no next move when checking a dragon to protect a queen from being stolen",
         %{
           player: player,
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok, nil = _next_move} =
               PlayValidator.check(
                 :play,
                 player.position,
                 [card_position],
                 rules,
                 table
               )
    end

    @tag player_turn: :opponent,
         waiting_on_player: :player,
         waiting_on_action: :block_place_queen_back_on_board,
         cards_in_player_hand: [:wand]
    test "returns success with no next move when checking a wand to protect a queen from being placed back on the board",
         %{
           player: player,
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok, nil = _next_move} =
               PlayValidator.check(
                 :play,
                 player.position,
                 [card_position],
                 rules,
                 table
               )
    end

    @tag player_turn: :opponent,
         waiting_on_player: :player,
         waiting_on_action: :block_place_queen_back_on_board,
         cards_in_player_hand: [:dragon]
    test "returns error when checking a dragon to protect a queen from being placed back on the board",
         %{
           player: player,
           rules: rules,
           table: table
         } do
      card_position = 1

      assert :error =
               PlayValidator.check(
                 :play,
                 player.position,
                 [card_position],
                 rules,
                 table
               )
    end

    @tag player_turn: :opponent,
         waiting_on_player: :player,
         waiting_on_action: :block_steal_queen,
         cards_in_player_hand: [:wand]
    test "returns error when checking a wand to protect a queen from being stolen",
         %{
           player: player,
           rules: rules,
           table: table
         } do
      card_position = 1

      assert :error =
               PlayValidator.check(
                 :play,
                 player.position,
                 [card_position],
                 rules,
                 table
               )
    end

    # TODO>>>> Could be a good place to implement a property test where I test player playing every other card in the deck to protect the queen
    # test "errors when playing any other card", %{
    #   rules: rules
    # } do
    #   for card when card.type not in [:wand] <- table.cards do
    #     
    #   end
    # end
  end

  # TODO>>>> Finish all these 👇👇👇
  # when it's the player's turn (ex: king, jester, knight, or sleeping potion)
  describe "check/5 :play, " do
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
    # describe "check/5 :discard, when it's the player's turn," do
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

  defp setup_game_table(_ctx) do
    player = Player.new("Ron")
    opponent = Player.new("Leslie")

    table = Table.new([player, opponent])

    [
      player: Table.get_player(table, 1),
      opponent: Table.get_player(table, 2),
      table: table
    ]
  end

  defp setup_rules_state(ctx) do
    rules =
      Rules.new()
      |> Map.replace(:state, :playing)
      |> Map.replace(:player_count, length(ctx.table.players))

    [rules: rules]
  end

  # TODO>>>> update to account for test setups for 
  # - number cards
  # - multiple cards (same or different types)
  defp setup_cards_in_player_hand(
         ctx = %{
           cards_in_player_hand: [card_type]
         }
       ) do
    card = %Card{type: card_type}

    table = add_cards_to_player_hand(ctx.table, [card], ctx.player.position)

    [table: table]
  end

  defp setup_cards_in_player_hand(_ctx) do
    :ok
  end

  defp setup_player_turn(ctx = %{player_turn: player_turn}) do
    rules = Map.replace(ctx.rules, :player_turn, ctx[player_turn].position)

    [rules: rules]
  end

  defp setup_player_turn(_ctx) do
    :ok
  end

  defp setup_waiting_on(
         ctx = %{
           waiting_on_player: waiting_on_player,
           waiting_on_action: waiting_on_action
         }
       ) do
    rules =
      Map.replace(ctx.rules, :waiting_on, %{
        player_position: ctx[waiting_on_player].position,
        action: waiting_on_action
      })

    [rules: rules]
  end

  defp setup_waiting_on(_ctx) do
    :ok
  end

  # TODO>>>> Add this as add_cards_to_player_hand function to Table? 
  # Might be useful in deal function refactor?
  defp add_cards_to_player_hand(table, cards, player_position) do
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

  # # TODO>>>> Maybe use with property test above?
  # defp empty_player_hand(table, player_position) do
  #   update_in(table.players, fn players ->
  #     remove_player_cards(players, player_position)
  #   end)
  # end
  #
  # defp remove_player_cards(players, player_position) do
  #   Enum.map(players, fn player ->
  #     if player.position == player_position do
  #       update_in(player.hand, fn _hand -> [] end)
  #     else
  #       player
  #     end
  #   end)
  # end
end
