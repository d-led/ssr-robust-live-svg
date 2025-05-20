defmodule BraitenbergVehiclesLiveWeb.WorldLive do
  use BraitenbergVehiclesLiveWeb, :live_view

  @width 800
  @height 600
  @radius 20

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(BraitenbergVehiclesLive.PubSub, "coordinates:ball")
    end

    {:ok,
     assign(socket,
       cx: 400,
       cy: 300,
       width: @width,
       height: @height,
       radius: @radius
     )}
  end

  def handle_info({:ball_coordinates, %{cx: cx, cy: cy}}, socket) do
    {:noreply, assign(socket, cx: cx, cy: cy)}
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
