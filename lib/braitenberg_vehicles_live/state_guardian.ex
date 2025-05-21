defmodule BraitenbergVehiclesLive.StateGuardian do
  use GenServer

  require Logger

  @pubsub BraitenbergVehiclesLive.PubSub
  @ball_topic "updates:ball"

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
    {:reply, :ok, %{data | ball_state: state}}
  end

  def handle_call(:return_ball_state, _from, data) do
    {:reply, data.ball_state || :not_found, data}
  end

  def handle_info({:ball_error, _reason}, data), do: {:noreply, data}

  def handle_info({:ball_state_restored, _mod}, data), do: {:noreply, data}

  def handle_info({:ball_behavior_changed_to, _mod}, data), do: {:noreply, data}

  def handle_info({:ball_coordinates, _coords}, data), do: {:noreply, data}

  def handle_info({:ball_state, state}, data) do
    {:noreply, %{data | ball_state: state}}
  end

  def handle_info(_msg, data), do: {:noreply, data}
end
