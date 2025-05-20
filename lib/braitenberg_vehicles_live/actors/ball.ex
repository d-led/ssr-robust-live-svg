defmodule BraitenbergVehiclesLive.Ball do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)
    radius = Keyword.get(opts, :radius)
    interval = Keyword.get(opts, :interval)
    movement_mod = Keyword.get(opts, :movement)
    movement = struct(movement_mod)

    state = %{
      # Initial x-pos
      cx: div(width, 2),
      # Initial y-pos
      cy: div(height, 2),
      dx: 4,
      dy: 3,
      width: width,
      height: height,
      radius: radius,
      interval: interval,
      movement: movement
    }

    schedule_tick(interval)
    {:ok, state}
  end

  # API
  def get_coordinates() do
    GenServer.call(__MODULE__, :get_coordinates)
  end

  # change the movement behaviour at runtime
  def set_movement(new_movement_mod) do
    GenServer.cast(__MODULE__, {:set_movement, new_movement_mod})
  end

  def nudge do
    GenServer.cast(__MODULE__, :nudge)
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

  def handle_cast({:set_movement, new_movement_module}, state) do
    {:noreply,
     %{state | movement: struct(new_movement_module), last_good_movement: new_movement_module}}
  end

  def handle_cast(:nudge, state) do
    {dx, dy} = random_nonzero_delta()
    {:noreply, %{state | dx: dx, dy: dy}}
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
end
