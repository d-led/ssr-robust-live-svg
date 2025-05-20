defmodule BraitenbergVehiclesLiveWeb.WorldLive do
  alias BraitenbergVehiclesLive.Ball
  use BraitenbergVehiclesLiveWeb, :live_view

  def mount(_params, _session, socket) do
    config =
      Keyword.merge(
        Application.get_env(:braitenberg_vehicles_live, :cell, []),
        Application.get_env(:braitenberg_vehicles_live, :ball, [])
      )

    width = Keyword.get(config, :width)
    height = Keyword.get(config, :height)
    radius = Keyword.get(config, :radius)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(BraitenbergVehiclesLive.PubSub, "coordinates:ball")
    end

    {cx, cy} = Ball.get_coordinates()

    {:ok,
     assign(socket,
       cx: cx,
       cy: cy,
       width: width,
       height: height,
       radius: radius
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
