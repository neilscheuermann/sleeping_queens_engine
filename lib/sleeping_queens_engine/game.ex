defmodule SleepingQueensEngine.Game do
  use GenServer

  alias SleepingQueensEngine.Rules
  alias SleepingQueensEngine.Table
  alias SleepingQueensEngine.Player

  @doc """
  Names a process using the "via" tuple for inserting and finding processes from the Registry
  """
  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  ###
  # Client Functions
  #

  def start_link(name) when is_binary(name),
    do: GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  def add_player(game, name) when is_binary(name),
    do: GenServer.call(game, {:add_player, name})

  def start_game(game),
    do: GenServer.call(game, :start_game)

  # def deal_cards(game),
  #   do: GenServer.call(game, :deal_cards)
  #
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
  def init(name) do
    first_player = Player.new(name)

    initial_state = %{
      table: Table.new([first_player]),
      rules: Rules.new()
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call({:add_player, name}, _from, state) do
    player = Player.new(name)

    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      {:ok, table} = Table.add_player(state.table, player)

      state
      |> update_table(table)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  @impl GenServer
  def handle_call(:start_game, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :start_game) do
      state
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  # @impl GenServer
  # def handle_call(:deal_cards, _from, state) do
  #   with {:ok, rules} <- Rules.check(state.rules, :deal_cards),
  #        table <- Table.deal_cards(state.table) do
  #     state
  #     |> update_rules(rules)
  #     |> update_table(table)
  #     |> reply_success(:ok)
  #   else
  #     :error -> {:reply, :error, state}
  #   end
  # end
  #
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
  #     reply_success(state, {:ok, next_action})
  #   else
  #     {:error, error} -> {:reply, {:error, error}, state}
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
  #     |> reply_success(:ok)
  #   else
  #     :error -> {:reply, :error, state}
  #   end
  # end

  ###
  # Private Functions
  #
  defp update_table(state, table), do: put_in(state.table, table)
  defp update_rules(state, rules), do: put_in(state.rules, rules)
  defp reply_success(state, reply), do: {:reply, reply, state}
end
