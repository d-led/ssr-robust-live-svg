defmodule SsrRobustLiveSvg.ClusterInfoServer do
  use GenServer

  @name __MODULE__
  @pubsub SsrRobustLiveSvg.PubSub
  @topic "updates:cluster"
  @interval 3_000

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
    version = SsrRobustLiveSvg.VersionServer.get_version()
    machine_id = Application.get_env(:ssr_robust_live_svg, :machine_id)

    other_nodes =
      Node.list()
      |> Enum.map(fn n ->
        v =
          :rpc.call(n, SsrRobustLiveSvg.VersionServer, :get_version, [])
          |> case do
            {:badrpc, _} -> "unknown"
            v -> v
          end

        m_id =
          :rpc.call(n, Application, :get_env, [:ssr_robust_live_svg, :machine_id])
          |> case do
            {:badrpc, _} -> nil
            m_id -> m_id
          end

        %{node: n, version: v, machine_id: m_id}
      end)

    ball_node =
      case Horde.Registry.lookup(
             SsrRobustLiveSvg.HordeRegistry,
             SsrRobustLiveSvg.Ball
           ) do
        [{pid, _value}] -> :erlang.node(pid)
        [] -> :not_found
      end

    %{
      node: node,
      version: version,
      machine_id: machine_id,
      other_nodes: other_nodes,
      ball_node: ball_node
    }
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @interval)
  end
end
