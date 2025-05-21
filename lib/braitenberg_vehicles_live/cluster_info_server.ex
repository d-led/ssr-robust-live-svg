defmodule BraitenbergVehiclesLive.ClusterInfoServer do
  use GenServer

  @name __MODULE__
  @pubsub BraitenbergVehiclesLive.PubSub
  @topic "updates:cluster"
  @interval 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def get_cluster_info do
    GenServer.call(@name, :get_cluster_info)
  end

  @impl true
  def init(state) do
    schedule_poll()
    {:ok, state}
  end

  @impl true
  def handle_call(:get_cluster_info, _from, state) do
    {:reply, fetch_cluster_info(), state}
  end

  @impl true
  def handle_info(:poll, state) do
    info = fetch_cluster_info()
    Phoenix.PubSub.local_broadcast(@pubsub, @topic, {:cluster_info, info})
    schedule_poll()
    {:noreply, state}
  end

  defp fetch_cluster_info do
    node = Node.self()
    version = BraitenbergVehiclesLive.VersionServer.get_version()

    other_nodes =
      Node.list()
      |> Enum.map(fn n ->
        v =
          :rpc.call(n, BraitenbergVehiclesLive.VersionServer, :get_version, [])
          |> case do
            {:badrpc, _} -> "unknown"
            v -> v
          end

        {n, v}
      end)

    # Query Horde for Ball location
    ball_node =
      case Horde.Registry.lookup(
             BraitenbergVehiclesLive.HordeRegistry,
             BraitenbergVehiclesLive.Ball
           ) do
        [{pid, _value}] -> :erlang.node(pid)
        [] -> :not_found
      end

    # |> IO.inspect(label: "Ball node")
    # Horde.Registry.select(BraitenbergVehiclesLive.HordeRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> IO.inspect(label: "all processes")

    %{
      node: node,
      version: version,
      other_nodes: other_nodes,
      ball_node: ball_node
    }
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @interval)
  end
end
