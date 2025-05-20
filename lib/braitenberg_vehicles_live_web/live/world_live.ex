defmodule BraitenbergVehiclesLiveWeb.WorldLive do
  alias BraitenbergVehiclesLive.Ball
  use BraitenbergVehiclesLiveWeb, :live_view

  @mirror_jump BraitenbergVehiclesLive.MirrorJump
  @random_rebound BraitenbergVehiclesLive.RandomRebound

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
       radius: radius,
       movement: :mirror_jump
     )}
  end

  def handle_info({:ball_coordinates, %{cx: cx, cy: cy}}, socket) do
    {:noreply, assign(socket, cx: cx, cy: cy)}
  end

  def handle_event("set_movement", %{"movement" => "mirror_jump"}, socket) do
    Ball.set_movement(@mirror_jump)
    {:noreply, assign(socket, movement: :mirror_jump)}
  end

  def handle_event("set_movement", %{"movement" => "random_rebound"}, socket) do
    Ball.set_movement(@random_rebound)
    {:noreply, assign(socket, movement: :random_rebound)}
  end

  def handle_event("nudge_ball", _params, socket) do
    Ball.nudge()
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-start min-h-screen bg-base-200">
      <div class="card shadow-xl bg-base-100 p-6">
        <div class="grid gap-4 mb-4" style="grid-template-columns: auto 1fr;">
          <div class="contents">
            <span class="font-semibold col-start-1">Ball movement:</span>
            <div class="flex gap-4 col-start-2">
              <button
                phx-click="set_movement"
                phx-value-movement="mirror_jump"
                disabled={@movement == :mirror_jump}
                class={"btn btn-primary btn-sm" <> if(@movement == :mirror_jump, do: " btn-disabled", else: "")}
              >
                MirrorJump
              </button>
              <button
                phx-click="set_movement"
                phx-value-movement="random_rebound"
                disabled={@movement == :random_rebound}
                class={"btn btn-secondary btn-sm" <> if(@movement == :random_rebound, do: " btn-disabled", else: "")}
              >
                RandomRebound
              </button>
            </div>
          </div>
          <div class="contents">
            <span class="font-semibold col-start-1">Ball control:</span>
            <div class="col-start-2">
              <button phx-click="nudge_ball" class="btn btn-accent btn-sm">
                Nudge Ball
              </button>
            </div>
          </div>
        </div>
        <div class="flex justify-center">
          <svg
            viewBox={"0 0 #{@width} #{@height}"}
            width={@width}
            height={@height}
            style="border: 0.5px solid black;"
          >
            <circle cx={@cx} cy={@cy} r={@radius} fill="blue" />
          </svg>
        </div>
      </div>
    </div>
    """
  end
end
