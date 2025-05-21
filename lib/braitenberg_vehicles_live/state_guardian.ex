defmodule BraitenbergVehiclesLive.StateGuardian do
  use GenServer

  require Logger

  @pubsub BraitenbergVehiclesLive.PubSub
  @ball_topic "state:ball"

  # Starts the GenServer
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Stores the ball state (sync).
  """
  def keep_ball_state(state) do
    GenServer.call(__MODULE__, {:keep_ball_state, state})
  end

  @doc """
  Returns the last known ball state, or :not_found (sync).
  """
  def return_ball_state() do
    GenServer.call(__MODULE__, :return_ball_state)
  end

  # GenServer callbacks

  def init(_state) do
    Phoenix.PubSub.subscribe(@pubsub, @ball_topic)
    {:ok, %{ball_state: nil}}
  end

  def handle_call({:keep_ball_state, state}, _from, data) do
    Logger.debug("Keeping ball state")
    # Notify subscribers about the new ball state
    {:reply, :ok, %{data | ball_state: state}}
  end

  def handle_call(:return_ball_state, _from, data) do
    Logger.debug("Returning ball state")
    {:reply, data.ball_state || :not_found, data}
  end

  def handle_info({:ball_state, state}, data) do
    {:noreply, %{data | ball_state: state}}
  end

  def handle_info(_msg, data), do: {:noreply, data}
end
