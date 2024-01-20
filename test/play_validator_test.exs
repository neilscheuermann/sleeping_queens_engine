defmodule PlayValidatorTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.PlayValidator
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  # when it's waiting on player (ex: have a dragon or wand to protect a queen?)
  describe "check/5 :play, when waiting on player" do
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
    test "returns success with no next action when checking a dragon to protect a queen from being stolen",
         %{
           player: player,
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok, nil = _next_action} =
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

      assert {:ok, nil = _next_action} =
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

  # when it's the player's turn checking to play action card (ex: king, jester, knight, or sleeping potion)
  describe "check/5 :play, when is player's turn" do
    setup [
      :setup_game_table,
      :setup_rules_state,
      :setup_cards_in_player_hand,
      :setup_player_turn,
      :setup_waiting_on
    ]

    @tag player_turn: :player,
         cards_in_player_hand: [:king]
    test "successfully prompts current player to select queen when checking to play a king",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok,
              %{
                action: :select_queen,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 [card_position],
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:jester]
    test "successfully prompts current player to select a card when checking to play a jester",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok,
              %{
                action: :draw_for_jester,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 [card_position],
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:knight]
    test "successfully prompts currrent player to choose queen to steal when checking to play a knight",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok,
              %{
                action: :choose_queen_to_steal,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 [card_position],
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:sleeping_potion]
    test "successfully prompts current player to choose queen to place back on board when checking to play a sleeping potion",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok,
              %{
                action: :choose_queen_to_place_back_on_board,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 [card_position],
                 rules,
                 table
               )
    end
  end

  # when it's player's turn checking to dicard one or more cards
  describe "check/5 :discard, when it's the player's turn," do
    setup [
      :setup_game_table,
      :setup_rules_state,
      :setup_cards_in_player_hand,
      :setup_player_turn,
      :setup_waiting_on
    ]

    # TODO>>>> Could be a good place to implement a property test where I test player playing every other card in the deck to protect the queen
    @tag player_turn: :player,
         cards_in_player_hand: [:king]
    test "successfully returns nil for next_action when checking to discard a single card of any type",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_position = 1

      assert {:ok, nil = _next_action} =
               PlayValidator.check(
                 :discard,
                 player_position,
                 [card_position],
                 rules,
                 table
               )
    end

    # test "successfully returns nil for next_action when checking to discard 2 matching numbers",
    #      %{
    #        player: %{position: player_position},
    #        rules: rules,
    #        table: table
    #      } do
    # end
    #
    # test "returns error when checking to discard 2 non-matching numbers",
    #      %{
    #        player: %{position: player_position},
    #        rules: rules,
    #        table: table
    #      } do
    # end
    #
    # test "successfully returns nil for next_action when discarding 3 numbers that make a valid addition equation",
    #      %{
    #        rules: rules
    #      } do
    # end
    #
    # test "successfully returns nil for next_action when discarding 4 numbers that make a valid addition equation",
    #      %{
    #        rules: rules
    #      } do
    # end
    #
    # test "successfully returns nil for next_action when discarding 5 numbers that make a valid addition equation",
    #      %{
    #        rules: rules
    #      } do
    # end
    #
    # test "errors when trying to discard 3 number cards that make a valid addition equation", %{
    #   rules: rules
    # } do
    # end
    #
    # test "errors when trying to discard 4 number cards that make a valid addition equation", %{
    #   rules: rules
    # } do
    # end
    #
    # test "errors when trying to discard 5 number cards that make a valid addition equation", %{
    #   rules: rules
    # } do
    # end
    #
    # test "errors when trying to discard 2 matching action cards", %{
    #   rules: rules
    # } do
    # end
    #
    # test "errors when trying to discard one number card and one matching action card", %{
    #   rules: rules
    # } do
    # end
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
