defmodule QueenCardTest do
  use ExUnit.Case

  alias SleepingQueensEngine.QueenCard

  @special_queen_names ~w(rose strawberry cat dog)
  @valid_queen_values [5, 10, 15, 20]

  setup_all do
    queens_pile = QueenCard.queens_pile_shuffled()

    %{queens_pile: queens_pile}
  end

  describe "new/2" do
    test "returns a queen card with required fields when given a name and value" do
      name = "Some Queen"
      value = 15

      queen = QueenCard.new(name, value)

      assert %QueenCard{
               name: ^name,
               value: ^value,
               special?: false
             } = queen
    end

    test "returns special? as true if queen name is one of listed special queens" do
      special_name = Enum.random(@special_queen_names)

      queen = QueenCard.new(special_name, 15)

      assert queen.special?
    end
  end

  describe "queens_pile_shuffled/0" do
    test "returns a total of 16 queen cards", %{queens_pile: queens_pile} do
      assert Enum.count(queens_pile) == 16
      assert [%QueenCard{} | _rest] = queens_pile
    end

    test "returns the cards in a shuffled order", %{queens_pile: queens_pile} do
      new_queens_pile = QueenCard.queens_pile_shuffled()
      refute queens_pile == new_queens_pile
    end

    test "ensures each queen has a value of 5, 10, 15, or 20", %{
      queens_pile: queens_pile
    } do
      assert Enum.all?(queens_pile, &(&1.value in @valid_queen_values))
    end

    test "ensures four of the queen cards are special (rose, strawberry, cat, and dog)",
         %{
           queens_pile: queens_pile
         } do
      assert Enum.count(queens_pile, fn queen ->
               queen.special? and queen.name in @special_queen_names
             end) == 4
    end
  end
end
