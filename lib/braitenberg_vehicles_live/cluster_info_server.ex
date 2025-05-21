defmodule BraitenbergVehiclesLive.ClusterInfoServer do
  use GenServer

  @name __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def get_cluster_info do
    GenServer.call(@name, :get_cluster_info)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:get_cluster_info, _from, state) do
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

    {:reply, %{node: node, version: version, other_nodes: other_nodes}, state}
  end
end