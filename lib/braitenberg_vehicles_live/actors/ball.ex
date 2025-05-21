defmodule BraitenbergVehiclesLive.Ball do
  use GenServer
  require Logger

  @updates_topic "updates:ball"

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: via_horde(__MODULE__)) do
      {:ok, pid} ->
        Logger.info("Started a global instance of #{__MODULE__}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}")
        :ignore
    end
  end

  def init(opts) do
    # Try to restore state
    case BraitenbergVehiclesLive.StateGuardian.return_ball_state() do
      :not_found ->
        Logger.debug("Ball: No previous state found, starting fresh")

        width = Keyword.get(opts, :width)
        height = Keyword.get(opts, :height)
        radius = Keyword.get(opts, :radius)
        interval = Keyword.get(opts, :interval)
        movement_mod = Keyword.get(opts, :movement)
        movement = struct(movement_mod)

        state = %{
          cx: div(width, 2),
          cy: div(height, 2),
          dx: 4,
          dy: 3,
          width: width,
          height: height,
          radius: radius,
          interval: interval,
          movement: movement,
          last_good_movement_module: movement_mod
        }

        schedule_tick(interval)

        Phoenix.PubSub.broadcast(
          BraitenbergVehiclesLive.PubSub,
          @updates_topic,
          {:ball_behavior_changed_to, movement_mod}
        )

        {:ok, state}

      restored_state ->
        Logger.debug("Ball: Restored state found, resuming #{inspect(restored_state)}")

        schedule_tick(restored_state.interval)

        Phoenix.PubSub.broadcast(
          BraitenbergVehiclesLive.PubSub,
          @updates_topic,
          {:ball_state_restored, restored_state.last_good_movement_module}
        )

        Phoenix.PubSub.broadcast(
          BraitenbergVehiclesLive.PubSub,
          @updates_topic,
          {:ball_behavior_changed_to, restored_state.last_good_movement_module}
        )

        {:ok, restored_state}
    end
  end

  # API
  def get_coordinates() do
    GenServer.call(via_horde(), :get_coordinates)
  end

  def get_movement_module() do
    GenServer.call(via_horde(), :get_movement_module)
  end

  def set_movement(new_movement_mod) do
    GenServer.cast(via_horde(), {:set_movement, new_movement_mod})
  end

  def nudge() do
    GenServer.cast(via_horde(), :nudge)
  end

  # Callbacks

  def handle_info(:tick, %{movement: movement} = state) do
    {cx, cy, dx, dy} = BallMovement.move(movement, state)
    new_state = %{state | cx: cx, cy: cy, dx: dx, dy: dy}
    publish_coordinates(cx, cy)
    schedule_tick(state.interval)
    {:noreply, new_state}
  end

  def handle_call(:get_coordinates, _from, state) do
    {:reply, {state.cx, state.cy}, state}
  end

  def handle_call(:get_movement_module, _from, state) do
    {:reply, state.last_good_movement_module, state}
  end

  def handle_cast({:set_movement, new_movement_module}, state) do
    # struct() can fail
    new_state = %{
      state
      | movement: struct(new_movement_module),
        last_good_movement_module: new_movement_module
    }

    # if we're still alive, broadcast the new movement module
    Phoenix.PubSub.broadcast(
      BraitenbergVehiclesLive.PubSub,
      @updates_topic,
      {:ball_behavior_changed_to, new_movement_module}
    )

    {:noreply, new_state}
  end

  def handle_cast(:nudge, state) do
    {dx, dy} = random_nonzero_delta()
    {:noreply, %{state | dx: dx, dy: dy}}
  end

  # Save state before terminating (e.g., crash)
  def terminate(reason, state) do
    Logger.debug("Ball crashed, saving state")
    BraitenbergVehiclesLive.StateGuardian.keep_ball_state(state)

    Phoenix.PubSub.broadcast(
      BraitenbergVehiclesLive.PubSub,
      @updates_topic,
      {:ball_error, reason}
    )

    :ok
  end

  # details

  defp schedule_tick(interval) do
    Process.send_after(self(), :tick, interval)
  end

  defp publish_coordinates(cx, cy) do
    Phoenix.PubSub.broadcast(
      BraitenbergVehiclesLive.PubSub,
      "coordinates:ball",
      {:ball_coordinates, %{cx: cx, cy: cy}}
    )
  end

  defp random_nonzero_delta do
    dx = Enum.random([-5, -4, -3, 3, 4, 5])
    dy = Enum.random([-5, -4, -3, 3, 4, 5])
    {dx, dy}
  end

  def via_horde(name \\ __MODULE__),
    do: {:via, Horde.Registry, {BraitenbergVehiclesLive.HordeRegistry, name}}
end
