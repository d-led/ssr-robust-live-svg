defmodule BraitenbergVehiclesLive.StateGuardian do
  use GenServer

  @table :actor_state
  @pubsub BraitenbergVehiclesLive.PubSub
  @topic "updates:cluster"

  # Starts the GenServer
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def setup_mnesia_table do
    nodes = [node() | Node.list()]
    :mnesia.create_schema(nodes)
    :mnesia.start()
    :mnesia.create_table(@table, [
      {:attributes, [:module, :state]},
      {:ram_copies, nodes}
    ])
  end

  @doc """
  Stores the state for a given module.
  """
  def keep_state(module, state) do
    :mnesia.transaction(fn ->
      :mnesia.write({@table, module, state})
    end)
    :ok
  end

  @doc """
  Returns the state for a given module, or :not_found.
  """
  def return_state(module) do
    case :mnesia.transaction(fn ->
           :mnesia.read({@table, module})
         end) do
      {:atomic, [{@table, ^module, state}]} -> state
      _ -> :not_found
    end
  end

  # GenServer callbacks

  def init(state) do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
    {:ok, state}
  end

  def handle_cast({:keep_state, module, state}, data) do
    {:noreply, Map.put(data, module, state)}
  end

  def handle_call({:return_state, module}, _from, data) do
    case Map.fetch(data, module) do
      {:ok, state} -> {:reply, state, data}
      :error -> {:reply, :not_found, data}
    end
  end

  def handle_info({:cluster_info, %{other_nodes: other_nodes}}, state) do
    current_nodes = [node() | Node.list()]
    desired_nodes = [node() | Enum.map(other_nodes, fn {n, _v} -> n end)]

    # Add missing ram_copies
    Enum.each(desired_nodes -- current_nodes, fn n ->
      :mnesia.add_table_copy(@table, n, :ram_copies)
    end)

    # Remove extra ram_copies
    Enum.each(current_nodes -- desired_nodes, fn n ->
      :mnesia.del_table_copy(@table, n)
    end)

    {:noreply, state}
  end
end
