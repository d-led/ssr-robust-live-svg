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
end
