defmodule SleepingQueensEngine.Rules do
  alias __MODULE__

  @type valid_game_states() :: :initialized | :playing | :game_over
  @type t() :: %__MODULE__{
          state: valid_game_states(),
          player_count: pos_integer(),
          player_turn: pos_integer()
        }
  defstruct state: :initialized,
            player_count: 1,
            player_turn: 1

  @range_of_allowed_players 2..5
  @max_player_limit 5

  @spec new() :: Rules.t()
  def new(), do: %Rules{}

  @spec check(Rules.t(), atom()) :: {:ok, Rules.t()} | :error
  def check(
        %Rules{state: :initialized, player_count: player_count} = rules,
        :add_player
      )
      when player_count in 1..(@max_player_limit - 1) do
    {:ok, %Rules{rules | player_count: player_count + 1}}
  end

  def check(
        %Rules{state: :initialized, player_count: player_count} = rules,
        :remove_player
      )
      when player_count in @range_of_allowed_players do
    {:ok, %Rules{rules | player_count: player_count - 1}}
  end

  def check(
        %Rules{state: :initialized, player_count: player_count} = rules,
        :start_game
      )
      when player_count in @range_of_allowed_players do
    {:ok, %Rules{rules | state: :playing}}
  end

  def check(
        %Rules{
          state: :playing,
          player_count: player_count,
          player_turn: player_turn
        } = rules,
        :deal_cards
      ) when player_turn in 1..player_count do
    if player_turn == player_count do
      {:ok, %Rules{rules | player_turn: 1}}
    else
      {:ok, %Rules{rules | player_turn: player_turn + 1}}
    end
  end

  def check(
        %Rules{state: :playing} = rules,
        {:win_check, win_or_not}
      ) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  def check(_state, _action), do: :error
end
