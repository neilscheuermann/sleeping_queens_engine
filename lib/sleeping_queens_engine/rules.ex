defmodule SleepingQueensEngine.Rules do
  alias __MODULE__

  @type t() :: %__MODULE__{
          state: valid_game_states(),
          player_count: pos_integer(),
          player_turn: pos_integer(),
          waiting_on: nil | waiting_on(),
          queen_to_lose: nil | queen_to_lose()
        }

  @type player_position() :: pos_integer()
  @type valid_game_states() :: :initialized | :playing | :game_over
  @type waiting_on_actions() ::
          :select_queen
          | :draw_for_jester
          | :block_steal_queen
          | :block_place_queen_back_on_board
          | :steal_queen
          | :place_queen_back_on_board
          | :pick_spot_to_return_queen
          | :acknowledge_blocked_by_dog_or_cat_queen
          | :select_another_queen_from_rose
  @type waiting_on() :: %{
          player_position: player_position(),
          action: waiting_on_actions()
        }
  @type queen_to_lose() :: %{
          player_position: pos_integer(),
          queen_position: pos_integer()
        }

  defstruct state: :initialized,
            player_count: 0,
            player_turn: 1,
            waiting_on: nil,
            # TDOD::: Add tests
            queen_to_lose: nil

  @range_of_allowed_players 2..5
  @max_allowed_players 5

  @spec new() :: Rules.t()
  def new(), do: %Rules{}

  @spec check(Rules.t(), atom()) :: {:ok, Rules.t()} | :error
  def check(
        %Rules{state: :initialized, player_count: player_count} = rules,
        :add_player
      )
      when player_count in 0..(@max_allowed_players - 1) do
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
      )
      when player_turn in 1..player_count do
    if player_turn == player_count do
      {:ok, %Rules{rules | player_turn: 1}}
    else
      {:ok, %Rules{rules | player_turn: player_turn + 1}}
    end
  end

  # TODO::: Update tests
  def check(
        %Rules{
          state: :playing,
          player_turn: player_turn,
          waiting_on: nil
        } = rules,
        {:play, player_position, waiting_on, queen_to_lose}
      )
      when player_position == player_turn do
    {:ok, %Rules{rules | waiting_on: waiting_on, queen_to_lose: queen_to_lose}}
  end

  def check(
        %Rules{
          state: :playing,
          waiting_on: %{
            player_position: waiting_player_position
          }
        } = rules,
        {:play, player_position, waiting_on, queen_to_lose}
      )
      when player_position == waiting_player_position do
    {:ok, %Rules{rules | waiting_on: waiting_on, queen_to_lose: queen_to_lose}}
  end

  def check(
        %Rules{state: :playing},
        {:play, _, _}
      ) do
    {:error, :not_your_turn}
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
