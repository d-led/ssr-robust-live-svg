defmodule BraitenbergVehiclesLiveWeb.WorldLive do
  use BraitenbergVehiclesLiveWeb, :live_view

  @width 800
  @height 600
  @radius 20
  @interval 30

  def mount(_params, _session, socket) do
    if connected?(socket), do: schedule_tick()

    {:ok,
     assign(socket,
       cx: 400,
       cy: 300,
       dx: 4,
       dy: 3,
       width: @width,
       height: @height,
       radius: @radius
     )}
  end

  def handle_info(:tick, socket) do
    {cx, cy, dx, dy} = move_ball(socket.assigns)
    schedule_tick()
    {:noreply, assign(socket, cx: cx, cy: cy, dx: dx, dy: dy)}
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

  defp schedule_tick do
    Process.send_after(self(), :tick, @interval)
  end

  def render(assigns) do
    ~H"""
    <svg
      viewBox={"0 0 #{@width} #{@height}"}
      width={@width}
      height={@height}
      style="border: 0.5px solid black;"
    >
      <circle cx={@cx} cy={@cy} r={@radius} fill="blue" />
    </svg>
    """
  end
end
