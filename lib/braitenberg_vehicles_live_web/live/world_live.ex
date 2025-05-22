defmodule BraitenbergVehiclesLiveWeb.WorldLive do
  alias BraitenbergVehiclesLive.Ball
  use BraitenbergVehiclesLiveWeb, :live_view
  import BraitenbergVehiclesLiveWeb.CircleComponent

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
      Phoenix.PubSub.subscribe(BraitenbergVehiclesLive.PubSub, "updates:cluster")
    end

    # query the ball for its actuals
    {cx, cy} = Ball.get_coordinates()
    movement_mod = Ball.get_movement_module()

    %{node: node, version: version, other_nodes: other_nodes, ball_node: ball_node} =
      BraitenbergVehiclesLive.ClusterInfoServer.get_cluster_info()

    {:ok,
     assign(socket,
       cx: cx,
       cy: cy,
       width: width,
       height: height,
       radius: radius,
       movement: movement_mod,
       available_ball_behaviors: available_ball_behaviors,
       alerts: [],
       node: node,
       version: version,
       other_nodes: other_nodes,
       ball_node: ball_node,
       kill_attempts: %{}
     )}
  end

  def handle_info({:ball_coordinates, %{cx: cx, cy: cy}}, socket) do
    {:noreply, assign(socket, cx: cx, cy: cy)}
  end

  def handle_info({:ball_error, reason}, socket) do
    id = System.unique_integer([:positive])
    # Use Exception.format_exit/1 for a user-friendly message
    msg =
      case reason do
        nil -> "Unknown error"
        _ -> Exception.format_exit(reason)
      end

    alert = %{id: id, type: :error, msg: "Ball crashed: #{msg}"}
    schedule_alert_removal(id)
    {:noreply, update(socket, :alerts, &[alert | &1])}
  end

  def handle_info({:ball_state_restored, mod}, socket) do
    id = System.unique_integer([:positive])
    mod_name = mod |> Module.split() |> List.last()
    alert = %{id: id, type: :warning, msg: "Ball state restored. Movement: #{mod_name}"}
    schedule_alert_removal(id)
    {:noreply, update(socket, :alerts, &[alert | &1])}
  end

  def handle_info({:ball_behavior_changed_to, mod}, socket) do
    id = System.unique_integer([:positive])
    mod_name = mod |> Module.split() |> List.last()
    alert = %{id: id, type: :info, msg: "Ball behavior changed to #{mod_name}"}
    schedule_alert_removal(id)

    socket =
      socket
      |> assign(movement: mod)
      |> update(:alerts, &[alert | &1])

    {:noreply, socket}
  end

  def handle_info({:remove_alert, id}, socket) do
    {:noreply, update(socket, :alerts, fn alerts -> Enum.reject(alerts, &(&1.id == id)) end)}
  end

  def handle_info(
        {:cluster_info,
         %{node: node, version: version, other_nodes: other_nodes, ball_node: ball_node}},
        socket
      ) do
    {:noreply,
     assign(socket, node: node, version: version, other_nodes: other_nodes, ball_node: ball_node)}
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

  def handle_event("kill_node", %{"node" => node_str}, socket) do
    node = String.to_existing_atom(node_str)
    now = System.monotonic_time(:millisecond)
    kill_attempts = Map.get(socket.assigns, :kill_attempts, %{})

    {timestamps, kill_attempts} =
      case Map.get(kill_attempts, node, []) do
        times ->
          # keep the last 1 second
          recent = Enum.filter(times, fn t -> now - t < 1_000 end)
          {[now | recent], Map.put(kill_attempts, node, [now | recent])}
      end

    if length(timestamps) >= 3 do
      # reset attempts after ok
      kill_attempts = Map.delete(kill_attempts, node)
      :rpc.cast(node, BraitenbergVehiclesLive.NodeKillSwitch, :kill_node, [1])
      {:noreply, assign(socket, kill_attempts: kill_attempts)}
    else
      {:noreply, assign(socket, kill_attempts: kill_attempts)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-start min-h-screen bg-base-200 px-2">
      <div class="card shadow-xl bg-base-100 p-4 sm:p-6 w-full max-w-[800px] flex flex-col gap-4">
        <div class="flex flex-col gap-2">
          <span class="font-semibold">Ball movement:</span>
          <div class="flex flex-wrap gap-2">
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
        <div class="flex flex-col gap-2">
          <span class="font-semibold">Ball control:</span>
          <button phx-click="nudge_ball" class="btn btn-accent btn-sm w-auto self-start">
            Nudge Ball
          </button>
        </div>
        <div class="flex gap-2 flex-wrap py-1">
          <span class="badge badge-info font-bold">
            <strong>
              <span title={to_string(@node)}>
                {@version}@{node_name(@node)}
              </span>
            </strong>
          </span>
          <%= for {node, version} <- @other_nodes do %>
            <span class="badge badge-outline flex items-center">
              <span title={to_string(node)}>
                {version}@{node_name(node)}
              </span>
              <button
                phx-click="kill_node"
                phx-value-node={to_string(node)}
                class="btn btn-ghost btn-xs ml-1"
                title="Kill node"
                style="padding:0 0.2em;vertical-align:middle;"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="inline-block" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </span>
          <% end %>
          <span class="badge badge-soft badge-info">
            <span title={to_string(@ball_node)}>
              Ball@{node_name(@ball_node)}
            </span>
          </span>
        </div>
        <div class="flex justify-center relative w-full">
          <div class="w-full max-w-[800px]">
            <svg
              viewBox={"0 0 #{@width} #{@height}"}
              width="100%"
              height="auto"
              style="border: 0.5px solid black; display: block; aspect-ratio: #{@width}/#{@height};"
            >
              <.circle cx={@cx} cy={@cy} r={@radius} />
            </svg>
          </div>
        </div>
        <div class="flex flex-col justify-center w-full gap-2">
          <%= for alert <- Enum.reverse(@alerts) do %>
            <div
              role="alert"
              class={"alert alert-#{alert.type} w-full flex justify-center"}
              id={"alert-#{alert.id}"}
              style="pointer-events: none;"
            >
              <span style="pointer-events: auto;">{alert.msg}</span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp schedule_alert_removal(id) do
    Process.send_after(self(), {:remove_alert, id}, 2_000)
  end

  defp node_name(node) do
    node
    |> to_string()
    |> String.split("@")
    |> case do
      [first, second] ->
        short_first =
          if String.length(first) > 8 do
            String.slice(first, 0, 8) <> "…"
          else
            first
          end

        short_second =
          if String.length(second) > 8 do
            "…" <> String.slice(second, -8, 8)
          else
            second
          end

        "#{short_first}@#{short_second}"

      [single] ->
        if String.length(single) > 16 do
          String.slice(single, 0, 16) <> "…"
        else
          single
        end

      _ ->
        inspect(node)
    end
  end
end
