defmodule BraitenbergVehiclesLive.Ball do
  use GenServer

  @width 800
  @height 600
  @radius 20
  @interval 30

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    state = %{
      cx: 400,
      cy: 300,
      dx: 4,
      dy: 3,
      width: @width,
      height: @height,
      radius: @radius
    }

    schedule_tick()
    {:ok, state}
  end

  # API for later initial rendering
  def get_coordinates do
    GenServer.call(__MODULE__, :get_coordinates)
  end

  # Callbacks

  def handle_info(:tick, state) do
    {cx, cy, dx, dy} = move_ball(state)
    new_state = %{state | cx: cx, cy: cy, dx: dx, dy: dy}
    publish_coordinates(cx, cy)
    schedule_tick()
    {:noreply, new_state}
  end

  defp move_ball(%{cx: cx, cy: cy, dx: dx, dy: dy}) do
    next_cx = cx + dx
    next_cy = cy + dy

    new_dx =
      cond do
        next_cx - @radius <= 0 and dx < 0 -> -dx
        next_cx + @radius >= @width and dx > 0 -> -dx
        true -> dx
      end

    new_dy =
      cond do
        next_cy - @radius <= 0 and dy < 0 -> -dy
        next_cy + @radius >= @height and dy > 0 -> -dy
        true -> dy
      end

    {cx + new_dx, cy + new_dy, new_dx, new_dy}
  end

  def handle_call(:get_coordinates, _from, state) do
    {:reply, {state.cx, state.cy}, state}
  end

  # details

  defp schedule_tick do
    Process.send_after(self(), :tick, @interval)
  end

  defp publish_coordinates(cx, cy) do
    Phoenix.PubSub.broadcast(
      BraitenbergVehiclesLive.PubSub,
      "coordinates:ball",
      {:ball_coordinates, %{cx: cx, cy: cy}}
    )
  end
end
