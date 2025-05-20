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

    available_ball_behaviors =
      Application.get_env(:braitenberg_vehicles_live, :available_ball_behaviors)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(BraitenbergVehiclesLive.PubSub, "coordinates:ball")
      Phoenix.PubSub.subscribe(BraitenbergVehiclesLive.PubSub, "updates:ball")
    end

    # query the ball for its actuals
    {cx, cy} = Ball.get_coordinates()
    movement_mod = Ball.get_movement_module()

    {:ok,
     assign(socket,
       cx: cx,
       cy: cy,
       width: width,
       height: height,
       radius: radius,
       movement: movement_mod,
       available_ball_behaviors: available_ball_behaviors
     )}
  end

  def handle_info({:ball_coordinates, %{cx: cx, cy: cy}}, socket) do
    {:noreply, assign(socket, cx: cx, cy: cy)}
  end

  def handle_info({:ball_behavior_changed_to, mod}, socket) do
    {:noreply, assign(socket, movement: mod)}
  end

  def handle_event("set_movement", %{"movement" => movement}, socket) do
    available = socket.assigns.available_ball_behaviors

    movement = movement |> String.to_existing_atom()

    mod =
      available
      |> Enum.find(fn mod ->
        mod == movement
      end)

    if mod do
      Ball.set_movement(mod)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
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
              <%= for mod <- @available_ball_behaviors do %>
                <% mod_name = mod |> Module.split() |> List.last() %>
                <button
                  phx-click="set_movement"
                  phx-value-movement={mod}
                  disabled={@movement == mod}
                  class={"btn btn-primary btn-sm" <> if(@movement == mod, do: " btn-disabled", else: "")}
                >
                  {mod_name}
                </button>
              <% end %>
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
