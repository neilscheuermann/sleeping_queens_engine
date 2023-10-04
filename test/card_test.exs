defmodule CardTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Card

  setup_all do
    draw_pile = Card.draw_pile_shuffled()

    %{draw_pile: draw_pile}
  end

  describe "draw_pile_shuffled/1" do
    test "it returns 68 total cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile) == 68
    end

    test "it returns 40 number cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile, fn card -> card.type == :number end) == 40
    end

    test "it returns 10 king cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile, fn card -> card.type == :king end) == 10
    end

    test "it returns 4 jester cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile, fn card -> card.type == :jester end) == 4
    end

    test "it returns 4 knight cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile, fn card -> card.type == :knight end) == 4
    end

    test "it returns 4 sleeping_potion cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile, fn card -> card.type == :sleeping_potion end) ==
               4
    end

    test "it returns 3 dragon cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile, fn card -> card.type == :dragon end) == 3
    end

    test "it returns 3 wand cards", %{draw_pile: draw_pile} do
      assert Enum.count(draw_pile, fn card -> card.type == :wand end) == 3
    end
  end

  describe "shuffle/1" do
    test "it returns the cards in a shuffled order", %{draw_pile: draw_pile} do
      draw_pile_shuffled = Card.shuffle(draw_pile)

      refute draw_pile == draw_pile_shuffled
    end
  end
end
