defmodule SleepingQueensEngine.Game do
  use GenServer

  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table
  alias SleepingQueensEngine.Player

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

  def add_player(game, name) when is_binary(name),
    do: GenServer.call(game, {:add_player, name})

  def start_game(game),
    do: GenServer.call(game, :start_game)

  def get_state(game),
    do: GenServer.call(game, :get_state)

  def deal_cards(game),
    do: GenServer.call(game, :deal_cards)

  # def can_play_cards?(game, player_position, card_positions),
  #   do:
  #     GenServer.call(game, {:can_play_cards?, player_position, card_positions})
  #
  # def play_cards(game, player_position, card_positions),
  #   do: GenServer.call(game, {:play_cards, player_position, card_positions})

  ###
  # Server Callbacks
  #

  @impl GenServer
  def init(game_id) do
    players = []

    initial_state = %{
      game_id: game_id,
      table: Table.new(players),
      rules: Rules.new()
    }

    {:ok, initial_state, @timeout}
  end

  @impl GenServer
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

  @impl GenServer
  def handle_call(:get_state, _from, state), do: reply(state, {:ok, state})

  @impl GenServer
  def handle_call(:start_game, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :start_game) do
      state
      |> update_rules(rules)
      |> reply(:ok)
    else
      :error -> reply(state, :error)
    end
  end

  @impl GenServer
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

  @impl GenServer
  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  # @impl GenServer
  # def handle_call(
  #       {:can_play_cards?, player_position, card_positions},
  #       _from,
  #       state
  #     ) do
  #   with {:ok, next_action} <-
  #          Rules.validate_play(
  #            state.rules,
  #            state.table,
  #            player_position,
  #            card_positions
  #          ) do
  #     reply(state, {:ok, next_action})
  #   else
  # {:error, error} -> reply(state, {:error, error})
  #   end
  # end
  #
  # @impl GenServer
  # def handle_call({:play_cards, player_position, card_positions}, _from, state) do
  #   with {:ok, waiting_on} <-
  #          Table.validate_play(state.table, player_position, card_positions),
  #        {:ok, next_action} <-
  #          Rules.validate_play(
  #            state.rules,
  #            state.table,
  #            player_position,
  #            card_positions
  #          ),
  #        {:ok, rules} <-
  #          Rules.check(
  #            state.rules,
  #            {:play, player_position, next_action}
  #          ),
  #        table <-
  #          Table.discard_cards(state.table, player_position, card_positions) do
  #     state
  #     |> update_rules(rules)
  #     |> update_table(table)
  #     |> reply(:ok)
  #   else
  #     :error -> reply(state, :error)
  #   end
  # end

  ###
  # Private Functions
  #
  defp update_table(state, table), do: put_in(state.table, table)
  defp update_rules(state, rules), do: put_in(state.rules, rules)
  defp reply(state, reply), do: {:reply, reply, state, @timeout}
end
