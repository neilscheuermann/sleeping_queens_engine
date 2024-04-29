defmodule RulesTest do
  use ExUnit.Case

  alias SleepingQueensEngine.Rules

  @range_of_allowed_players 2..5
  @max_allowed_players 5

  describe "new/0" do
    test "returns a Rules struct with required fields to track game state" do
      rules = Rules.new()

      assert %Rules{
               state: :initialized,
               player_count: 0,
               player_turn: 1
             } = rules
    end
  end

  describe "check/2, when state :initialized" do
    setup do
      rules = Rules.new()

      %{rules: rules}
    end

    test ":add_player successfully increments :player_count by 1", %{
      rules: rules
    } do
      assert rules.player_count == 0
      assert {:ok, rules} = Rules.check(rules, :add_player)
      assert rules.player_count == 1
    end

    test ":add_player errors when player_count is at max limit", %{rules: rules} do
      rules = Map.replace(rules, :player_count, @max_allowed_players)

      assert :error = Rules.check(rules, :add_player)
    end

    test ":remove_player successfully decrements :player_count by 1", %{
      rules: rules
    } do
      rules = Map.replace(rules, :player_count, 2)

      assert {:ok, rules} = Rules.check(rules, :remove_player)
      assert rules.player_count == 1
    end

    test ":remove_player errors when player_count is at min limit", %{
      rules: rules
    } do
      assert :error = Rules.check(rules, :remove_player)
    end

    test ":start_game successfully updates state to :playing when enough players",
         %{rules: rules} do
      valid_player_count = Enum.random(@range_of_allowed_players)
      rules = Map.replace(rules, :player_count, valid_player_count)

      assert {:ok, rules} = Rules.check(rules, :start_game)
      assert rules.state == :playing
    end

    test ":start_game errors when player_count is outside allowed range", %{
      rules: rules
    } do
      invalid_player_count = 100
      rules = Map.replace(rules, :player_count, invalid_player_count)

      assert :error = Rules.check(rules, :start_game)
    end
  end

  describe "check/2, when state :playing" do
    setup do
      rules =
        Rules.new()
        |> Map.replace(:state, :playing)
        |> Map.replace(:player_count, 2)

      %{rules: rules}
    end

    test ":deal_cards successfully cylces through :player_turn within range of players",
         %{rules: rules} do
      rules =
        rules
        |> Map.replace(:player_count, 3)
        |> Map.replace(:player_turn, 3)

      assert rules.player_turn == 3
      assert {:ok, rules} = Rules.check(rules, :deal_cards)
      assert rules.player_turn == 1
      assert {:ok, rules} = Rules.check(rules, :deal_cards)
      assert rules.player_turn == 2
    end

    test ":deal_cards errors when player_turn is outside range of players", %{
      rules: rules
    } do
      rules =
        rules
        |> Map.replace(:player_count, 3)
        |> Map.replace(:player_turn, 100)

      assert :error = Rules.check(rules, :start_game)
    end

    test ":play returns success and updates waiting_on when it's the waiting_on player's turn",
         %{rules: rules} do
      waiting_player_position = 1

      rules =
        Map.replace(rules, :waiting_on, %{
          player_position: waiting_player_position
        })

      assert {:ok, rules} =
               Rules.check(rules, {:play, waiting_player_position, nil})

      refute rules.waiting_on
    end

    test ":play returns success and updates waiting_on when it's main player's turn",
         %{rules: rules} do
      player_position = 1
      rules = Map.replace(rules, :player_turn, player_position)

      refute rules.waiting_on

      new_waiting_on = %{}

      assert {:ok, rules} =
               Rules.check(rules, {:play, player_position, new_waiting_on})

      assert rules.waiting_on == new_waiting_on
    end

    test ":play errors when it's not the player's turn", %{
      rules: rules
    } do
      rules =
        rules
        |> Map.replace(:player_count, 3)
        |> Map.replace(:player_turn, 100)

      assert :error = Rules.check(rules, :start_game)
    end

    test ":win_check with :no_win successfully returns the rules unchanged", %{
      rules: rules
    } do
      assert {:ok, unchanged_rules} = Rules.check(rules, {:win_check, :no_win})
      assert unchanged_rules == rules
    end

    test ":win_check with :win successfully changes game state to :game_over",
         %{rules: rules} do
      assert {:ok, rules} = Rules.check(rules, {:win_check, :win})
      assert rules.state == :game_over
    end
  end
end
