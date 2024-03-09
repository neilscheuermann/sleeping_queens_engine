defmodule SleepingQueensEngine.GameSupervisor do
  use DynamicSupervisor

  alias SleepingQueensEngine.Game

  ###
  # Client Functions
  #

  # Using `name: __MODULE__` ensures there can only be one supervisor for
  # this module, and for us to reference it by module name rather than pid.
  def start_link(_options),
    do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def start_game(game_id) do
    spec = %{
      id: Game,
      start: {Game, :start_link, [game_id]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_game(game_id),
    do: DynamicSupervisor.terminate_child(__MODULE__, pid_from_id(game_id))

  defp pid_from_id(game_id) do
    game_id
    |> Game.via_tuple()
    |> GenServer.whereis()
  end

  ###
  # Server Callbacks
  #

  # Callback for `start_link`
  @impl true
  def init(:ok),
    do: DynamicSupervisor.init(strategy: :one_for_one)
end
