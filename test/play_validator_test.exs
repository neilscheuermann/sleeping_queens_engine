defmodule PlayValidatorTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.PlayValidator
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.QueenCard
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  # when it's the player's turn checking to play offensive action card (ex: king, jester, knight, or sleeping potion)
  describe "check/5 :play, when is player's turn" do
    setup [
      :setup_game_table,
      :setup_rules_state,
      :setup_cards_in_player_hand,
      :setup_select_queen_for_player,
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
      card_positions = [1]

      assert {:ok,
              %{
                action: :select_queen,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 card_positions,
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
      card_positions = [1]

      assert {:ok,
              %{
                action: :draw_for_jester,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:knight],
         # other player
         select_queen_for_player: 2
    test "successfully prompts currrent player to choose queen to steal when checking to play a knight if others have a queen",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1]

      assert {:ok,
              %{
                action: :steal_queen,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player, cards_in_player_hand: [:knight]
    test "errors when checking to play a knight if the only queen out is the strawberry queen",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      queen_card = %QueenCard{
        name: "strawberry",
        value: 10,
        special?: true
      }

      opponent_position = 2
      table = replace_player_queens_with(table, opponent_position, [queen_card])

      card_positions = [1]

      assert :error =
               PlayValidator.check(
                 :play,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:knight]
    test "errors when checking to play a knight if no others have a queen",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1]

      assert :error =
               PlayValidator.check(
                 :play,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:sleeping_potion],
         # other player
         select_queen_for_player: 2
    test "successfully prompts current player to choose queen to place back on board when checking to play a sleeping potion if others have a queen",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1]

      assert {:ok,
              %{
                action: :place_queen_back_on_board,
                player_position: ^player_position
              }} =
               PlayValidator.check(
                 :play,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:sleeping_potion]
    test "errors when checking to play a sleeping potion if no others have a queen",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1]

      assert :error =
               PlayValidator.check(
                 :play,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end
  end

  # when it's the player's turn checking to play defensive action card (ex: have a dragon or wand to protect a queen?)
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
    test "returns success with no waiting_on when checking a dragon to protect a queen from being stolen",
         %{
           player: player,
           rules: rules,
           table: table
         } do
      card_positions = [1]

      assert {:ok, nil = _waiting_on} =
               PlayValidator.check(
                 :play,
                 player.position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :opponent,
         waiting_on_player: :player,
         waiting_on_action: :block_place_queen_back_on_board,
         cards_in_player_hand: [:wand]
    test "returns success with no waiting_on when checking a wand to protect a queen from being placed back on the board",
         %{
           player: player,
           rules: rules,
           table: table
         } do
      card_positions = [1]

      assert {:ok, nil = _waiting_on} =
               PlayValidator.check(
                 :play,
                 player.position,
                 card_positions,
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
      card_positions = [1]

      assert :error =
               PlayValidator.check(
                 :play,
                 player.position,
                 card_positions,
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
      card_positions = [1]

      assert :error =
               PlayValidator.check(
                 :play,
                 player.position,
                 card_positions,
                 rules,
                 table
               )
    end

    # TODO::: Could be a good place to implement a property test where I test player playing every other card in the deck to protect the queen
    # test "errors when playing any other card", %{
    #   rules: rules
    # } do
    #   for card when card.type not in [:wand] <- table.cards do
    #     
    #   end
    # end
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

    for card_type <-
          [:king, :jester, :knight, :dragon, :wand, :sleeping_potion] ++
            Enum.to_list(1..10) do
      @tag player_turn: :player,
           cards_in_player_hand: [card_type]
      test "successfully returns nil for waiting_on when checking to discard a #{card_type}",
           %{
             player: %{position: player_position},
             rules: rules,
             table: table
           } do
        card_positions = [1]

        assert {:ok, nil = _waiting_on} =
                 PlayValidator.check(
                   :discard,
                   player_position,
                   card_positions,
                   rules,
                   table
                 )
      end
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 1]
    test "successfully returns nil for waiting_on when checking to discard 2 matching numbers",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2]

      assert {:ok, nil = _waiting_on} =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [6, 9]
    test "returns error when checking to discard 2 non-matching numbers",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2]

      assert :error =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 1, 2]
    test "successfully returns nil for waiting_on when checking to discard 3 numbers that make a valid addition equation",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2, 3]

      assert {:ok, nil} =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 1, 1, 3]
    test "successfully returns nil for waiting_on when checking to discard 4 numbers that make a valid addition equation",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2, 3, 4]

      assert {:ok, nil} =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 1, 1, 1, 4]
    test "successfully returns nil for waiting_on when checking to discard 5 numbers that make a valid addition equation",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2, 3, 4, 5]

      assert {:ok, nil} =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 1, 10]
    test "errors when checking to discard 3 number cards that do not make a valid addition equation",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2, 3]

      assert :error =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 1, 1, 10]
    test "errors when checking to discard 4 number cards that make a valid addition equation",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2, 3, 4]

      assert :error =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 1, 1, 1, 10]
    test "errors when checking to discard 5 number cards that make a valid addition equation",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2, 3, 4, 5]

      assert :error =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [:wand, :wand]
    test "errors when checking to discard 2 matching action cards",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2]

      assert :error =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, :wand]
    test "errors when checking to discard one number card and one action card",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2]

      assert :error =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end

    @tag player_turn: :player,
         cards_in_player_hand: [1, 3, :wand, :jester]
    test "errors when checking to discard multiple number and action cards",
         %{
           player: %{position: player_position},
           rules: rules,
           table: table
         } do
      card_positions = [1, 2, 3, 4]

      assert :error =
               PlayValidator.check(
                 :discard,
                 player_position,
                 card_positions,
                 rules,
                 table
               )
    end
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

  defp setup_cards_in_player_hand(
         %{
           cards_in_player_hand: card_types
         } = ctx
       ) do
    cards = Enum.map(card_types, &build_card/1)

    table = add_cards_to_player_hand(ctx.table, cards, ctx.player.position)

    [table: table]
  end

  defp setup_cards_in_player_hand(_ctx) do
    :ok
  end

  defp setup_select_queen_for_player(
         %{select_queen_for_player: player_position} = ctx
       ) do
    {:ok, table, _next_waiting_on} =
      Table.select_queen(ctx.table, {1, 1}, player_position)

    [table: table]
  end

  defp setup_select_queen_for_player(_ctx), do: :ok

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

  defp build_card(card_type) when is_integer(card_type),
    do: %Card{type: :number, value: card_type}

  defp build_card(card_type), do: %Card{type: card_type}

  # TODO::: Add this as add_cards_to_player_hand function to Table? 
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

  defp replace_player_queens_with(table, player_position, queens) do
    update_in(table.players, fn players ->
      Enum.map(players, fn player ->
        if player.position == player_position do
          %{player | queens: queens}
        else
          player
        end
      end)
    end)
  end

  # # TODO::: Maybe use with property test above?
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
