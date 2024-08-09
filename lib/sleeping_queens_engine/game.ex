defmodule SleepingQueensEngine.Game do
  use GenServer

  alias SleepingQueensEngine.PlayValidator
  alias SleepingQueensEngine.Player
  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table

  # 1 day
  @timeout 60 * 60 * 24 * 1000

  @doc """
  Names a process using the "via" tuple for inserting and finding processes from the Registry
  """
  def via_tuple(game_id), do: {:via, Registry, {Registry.Game, game_id}}

  ###
  # Client Functions
  #

  def start_link(game_id) when is_binary(game_id),
    do: GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))

  def get_state(game), do: GenServer.call(game, :get_state)

  def add_player(game, name) when is_binary(name),
    do: GenServer.call(game, {:add_player, name})

  def start_game(game), do: GenServer.call(game, :start_game)

  # TODO::: Can delete this
  def deal_cards(game), do: GenServer.call(game, :deal_cards)

  def validate_discard_selection(game, player_position, card_positions),
    do:
      GenServer.call(
        game,
        {:validate_discard_selection, player_position, card_positions}
      )

  def discard(game, player_position, card_positions),
    do: GenServer.call(game, {:discard, player_position, card_positions})

  def validate_play_selection(game, player_position, card_positions),
    do:
      GenServer.call(
        game,
        {:validate_play_selection, player_position, card_positions}
      )

  def play(game, player_position, card_positions),
    do: GenServer.call(game, {:play, player_position, card_positions})

  def select_queen(game, player_position, row, col),
    do: GenServer.call(game, {:select_queen, player_position, row, col})

  def draw_for_jester(game, player_position),
    do: GenServer.call(game, {:draw_for_jester, player_position})

  # TODO::: Add tests
  def select_opponent_queen(
        game,
        player_position,
        opponent_position,
        opponent_queen_position
      ),
      do:
        GenServer.call(
          game,
          {:select_opponent_queen, player_position, opponent_position,
           opponent_queen_position}
        )

  # TODO::: Add tests
  def lose_queen(game), do: GenServer.call(game, :lose_queen)

  # TODO::: Add tests
  def put_queen_back(game, queen_coordinate),
    do: GenServer.call(game, {:put_queen_back, queen_coordinate})

  ###
  # Server Callbacks
  #

  @impl true
  def init(game_id) do
    players = []

    initial_state = %{
      game_id: game_id,
      table: Table.new(players),
      rules: Rules.new()
    }

    {:ok, initial_state, @timeout}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: reply(state, state)

  @impl true
  def handle_call({:add_player, name}, _from, state) do
    player = Player.new(name)

    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      {:ok, table} = Table.add_player(state.table, player)

      state
      |> update_table(table)
      |> update_rules(rules)
      |> reply(:ok)
    else
      :error -> reply(state, :error)
    end
  end

  @impl true
  def handle_call(:start_game, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :start_game),
         table <- Table.deal_cards(state.table, state.rules.player_turn) do
      state
      |> update_rules(rules)
      |> update_table(table)
      |> reply(:ok)
    else
      :error -> reply(state, :error)
    end
  end

  @impl true
  def handle_call(:deal_cards, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :deal_cards),
         table <- Table.deal_cards(state.table, state.rules.player_turn) do
      state
      |> update_rules(rules)
      |> update_table(table)
      |> reply(:ok)
    else
      :error -> reply(state, :error)
    end
  end

  @impl true
  def handle_call(
        {:validate_discard_selection, player_position, card_positions},
        _from,
        state
      ) do
    resp =
      PlayValidator.check(
        :discard,
        player_position,
        card_positions,
        state.rules,
        state.table
      )

    reply(state, resp)
  end

  @impl true
  def handle_call(
        {:discard, player_position, card_positions},
        _from,
        state
      ) do
    with {:ok, nil = _waiting_on} <-
           PlayValidator.check(
             :discard,
             player_position,
             card_positions,
             state.rules,
             state.table
           ),
         {:ok, table} <-
           Table.discard_cards(state.table, card_positions, player_position),
         {:ok, rules} <- Rules.check(state.rules, :deal_cards),
         table <- Table.deal_cards(table, state.rules.player_turn) do
      state
      |> update_table(table)
      |> update_rules(rules)
      |> reply(:ok)
    else
      error -> reply(state, error)
    end
  end

  @impl true
  def handle_call(
        {:validate_play_selection, player_position, card_positions},
        _from,
        state
      ) do
    resp =
      PlayValidator.check(
        :play,
        player_position,
        card_positions,
        state.rules,
        state.table
      )

    reply(state, resp)
  end

  @impl true
  def handle_call(
        {:play, player_position, card_positions},
        _from,
        state
      ) do
    with {:ok, waiting_on} <-
           PlayValidator.check(
             :play,
             player_position,
             card_positions,
             state.rules,
             state.table
           ),
         {:ok, rules} <-
           Rules.check(state.rules, {:play, player_position, waiting_on, nil}),
         {:ok, table} <-
           Table.discard_cards(state.table, card_positions, player_position) do
      state
      |> update_table(table)
      |> update_rules(rules)
      |> reply(:ok)
    else
      error -> reply(state, error)
    end
  end

  @impl true
  def handle_call({:select_queen, player_position, row, col}, _from, state) do
    with %{action: :select_queen, player_position: waiting_player_position}
         when waiting_player_position == player_position <-
           state.rules.waiting_on,
         {:ok, table} <-
           Table.select_queen(
             state.table,
             {row, col},
             player_position
           ),
         {:ok, rules} <-
           Rules.check(state.rules, {:play, player_position, nil, nil}),
         {:ok, rules} <- Rules.check(rules, :deal_cards),
         table <- Table.deal_cards(table, state.rules.player_turn) do
      state
      |> update_rules(rules)
      |> update_table(table)
      |> reply(:ok)
    else
      _ -> reply(state, :error)
    end
  end

  @impl true
  def handle_call({:draw_for_jester, player_position}, _from, state) do
    with %{action: :draw_for_jester, player_position: waiting_player_position}
         when waiting_player_position == player_position <-
           state.rules.waiting_on,
         {:ok, table, waiting_on} <-
           Table.draw_for_jester(
             state.table,
             state.rules,
             player_position
           ),
         {:ok, rules} =
           Rules.check(state.rules, {:play, player_position, waiting_on, nil}) do
      state
      |> update_rules(rules)
      |> update_table(table)
      |> reply(:ok)
    else
      _ -> reply(state, :error)
    end
  end

  @impl true
  def handle_call(
        {:select_opponent_queen, player_position, opponent_position,
         opponent_queen_position},
        _from,
        state
      )
      when state.rules.waiting_on.action in [
             :steal_queen,
             :place_queen_back_on_board
           ] do
    next_action =
      case state.rules.waiting_on.action do
        :steal_queen -> :block_steal_queen
        :place_queen_back_on_board -> :block_place_queen_back_on_board
      end

    next_waiting_on = %{
      action: next_action,
      player_position: opponent_position
    }

    next_queen_to_lose = %{
      player_position: opponent_position,
      queen_position: opponent_queen_position
    }

    with {:ok, rules} <-
           Rules.check(
             state.rules,
             {:play, player_position, next_waiting_on, next_queen_to_lose}
           ) do
      state
      |> update_rules(rules)
      |> reply(:ok)
    else
      _ -> reply(state, :error)
    end
  end

  # lose queen to a knight (stolen)
  @impl true
  def handle_call(
        :lose_queen,
        _from,
        #  wating on the player to block the steal, but they chose not to
        %{rules: %{waiting_on: %{action: :block_steal_queen}}} = state
      ) do
    # No next action needed because the player get's the opponent's queen
    next_waiting_on = nil
    next_queen_to_lose = nil

    opponent_position = state.rules.waiting_on.player_position
    opponent_queen_position = state.rules.queen_to_lose.queen_position
    player_position = state.rules.player_turn

    with {:ok, rules} <-
           Rules.check(
             state.rules,
             # hack to get Rules.check to pass so I can update waiting_on and queen_to_lose
             {:play, state.rules.waiting_on.player_position, next_waiting_on,
              next_queen_to_lose}
           ),
         {:ok, table} <-
           Table.steal_queen(
             state.table,
             opponent_position,
             opponent_queen_position,
             player_position
           ),
         {:ok, rules} <- Rules.check(rules, :deal_cards),
         table <- Table.deal_cards(table, state.rules.player_turn) do
      state
      |> update_rules(rules)
      |> update_table(table)
      |> reply(:ok)
    else
      _ -> reply(state, :error)
    end
  end

  # lose queen to a sleeping poition (put back to sleep)
  @impl true
  def handle_call(
        :lose_queen,
        _from,
        #  wating on the player to block the steal, but they chose not to
        %{rules: %{waiting_on: %{action: :block_place_queen_back_on_board}}} =
          state
      ) do
    # This will leave the previously set `opponent_queen_position`
    next_waiting_on = %{
      action: :pick_spot_to_return_queen,
      player_position: state.rules.player_turn
    }

    next_queen_to_lose = state.rules.queen_to_lose

    with {:ok, rules} <-
           Rules.check(
             state.rules,
             # hack to get Rules.check to pass so I can update waiting_on and queen_to_lose
             {:play, state.rules.waiting_on.player_position, next_waiting_on,
              next_queen_to_lose}
           ) do
      state
      |> update_rules(rules)
      |> reply(:ok)
    else
      _ -> reply(state, :error)
    end
  end

  @impl true
  def handle_call(
        {:put_queen_back, queen_coordinate},
        _from,
        state
      ) do
    player_position = state.rules.queen_to_lose.player_position
    queen_position = state.rules.queen_to_lose.queen_position

    next_waiting_on = nil
    next_queen_to_lose = nil

    with {:ok, rules} <-
           Rules.check(
             state.rules,
             {:play, state.rules.waiting_on.player_position, next_waiting_on,
              next_queen_to_lose}
           ),
         {:ok, table} <-
           Table.place_queen_on_board(
             state.table,
             player_position,
             queen_position,
             queen_coordinate
           ),
         {:ok, rules} <- Rules.check(rules, :deal_cards),
         table <- Table.deal_cards(table, state.rules.player_turn) do
      state
      |> update_rules(rules)
      |> update_table(table)
      |> reply(:ok)
    else
      _ -> reply(state, :error)
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  ###
  # Private Functions
  #
  defp update_table(state, table), do: put_in(state.table, table)
  defp update_rules(state, rules), do: put_in(state.rules, rules)
  defp reply(state, reply), do: {:reply, reply, state, @timeout}
end
