defmodule SleepingQueensEngine.GameSupervisor do
  # TODO>>>> Replace with `DynamicSupervisor` to address the following type warnings.
  # ```
  # warning: :simple_one_for_one strategy is deprecated, please use DynamicSupervisor instead
  # warning: Supervisor.start_child/2 with a list of args is deprecated, please use DynamicSupervisor instead
  # ```
  use Supervisor

  alias SleepingQueensEngine.Game

  ###
  # Client Functions
  #

  # Using `name: __MODULE__` ensures there can only be one supervisor for
  # this module, and for us to reference it by module name rather than pid.
  def start_link(_options),
    do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def start_game(game_id),
    do: Supervisor.start_child(__MODULE__, [game_id])

  def stop_game(game_id), 
    do: Supervisor.terminate_child(__MODULE__, pid_from_id(game_id))

  defp pid_from_id(game_id) do
    game_id
    |> Game.via_tuple()
    |> GenServer.whereis()
  end

  ###
  # Server Callbacks
  #

  # Callback for `start_link`
  @impl Supervisor
  def init(:ok),
    # Supervise `Game` type processes with a simple one-for-one strategy.
    do: Supervisor.init([Game], strategy: :simple_one_for_one)
end
