defmodule SsrRobustLiveSvg.NodeListener do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    :net_kernel.monitor_nodes(true)
    Phoenix.PubSub.subscribe(SsrRobustLiveSvg.PubSub, "module:spread")
    {:ok, nil}
  end

  def handle_info({:nodeup, node}, state) do
    IO.puts("Node joined: #{inspect(node)}")
    SsrRobustLiveSvg.BehaviorModules.spread_modules()
    {:noreply, state}
  end

  def handle_info({:nodedown, node}, state) do
    IO.puts("Node left: #{inspect(node)}")
    {:noreply, state}
  end

  def handle_info({:got_module, from_node, module_name, object_code}, state) do
    SsrRobustLiveSvg.BehaviorModules.incoming_module(from_node, module_name, object_code)
    {:noreply, state}
  end
end
