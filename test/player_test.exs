defmodule PlayerTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Card
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.QueenCard

  @max_cards_allowed_in_hand 5

  setup do
    name = "Ron"
    player = Player.new(name)

    %{player: player}
  end

  describe "new/1" do
    test "returns a player with required fields when given a name" do
      name = "Ron"
      player = Player.new(name)

      assert %Player{
               hand: [],
               name: ^name,
               position: nil,
               queens: []
             } = player
    end

    test "throws match error if name is not a string" do
      assert_raise FunctionClauseError, fn ->
        not_a_string = 'Ron'
        Player.new(not_a_string)
      end
    end
  end

  describe "select_cards/2" do
    test "returns selected cards and the updated player with those cards removed from their hand",
         %{player: player} do
      hand = [
        %Card{type: :number, value: 1},
        %Card{type: :number, value: 2},
        %Card{type: :number, value: 3}
      ]

      player = Map.put(player, :hand, hand)

      assert {selected_cards, updated_player} =
               Player.select_cards(player, [1, 2])

      assert selected_cards == [
               %Card{type: :number, value: 1},
               %Card{type: :number, value: 2}
             ]

      assert %Player{} = updated_player
      assert updated_player.hand == [%Card{type: :number, value: 3}]
    end

    test "throws match error if no positions are selected", %{player: player} do
      assert_raise FunctionClauseError, fn ->
        Player.select_cards(player, [])
      end
    end

    test "throws match error if too many positions are selected", %{
      player: player
    } do
      assert_raise FunctionClauseError, fn ->
        Player.select_cards(player, [1, 2, 3, 4, 5, 6])
      end
    end
  end

  describe "add_card_to_hand/2" do
    test "returns an updated player with the given card added to the player's hand",
         %{
           player: player
         } do
      card = %Card{type: :number, value: 1}

      updated_player = Player.add_card_to_hand(player, card)

      assert %Player{} = updated_player
      assert updated_player.hand == [card]
    end

    test "throws match error if player already has 5 cards in their hand", %{
      player: player
    } do
      hand =
        for value <- 1..@max_cards_allowed_in_hand do
          %Card{type: :number, value: value}
        end

      player = Map.put(player, :hand, hand)

      assert_raise FunctionClauseError, fn ->
        Player.add_card_to_hand(player, [])
      end
    end
  end

  describe "add_queen/2" do
    test "returns an updated player with the given queen card added to the player's queens",
         %{
           player: player
         } do
      queen_card = %QueenCard{name: "rose", value: 5, special?: true}

      updated_player = Player.add_queen(player, queen_card)

      assert %Player{} = updated_player
      assert updated_player.queens == [queen_card]
    end
  end

  describe "lose_queen/2" do
    test "returns an updated player and the queen card found at the given queen card index",
         %{
           player: player
         } do
      queen_card = %QueenCard{name: "rose", value: 5, special?: true}

      player = Map.put(player, :queens, [queen_card])

      {updated_player, returned_queen_card} = Player.lose_queen(player, 0)

      assert %Player{} = updated_player
      assert updated_player.queens == []
      assert returned_queen_card == queen_card
    end
  end
end
