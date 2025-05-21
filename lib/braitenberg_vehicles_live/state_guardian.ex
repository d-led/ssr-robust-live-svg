defmodule BraitenbergVehiclesLive.StateGuardian do
  use GenServer

  require Logger

  @table :actor_state
  @pubsub BraitenbergVehiclesLive.PubSub
  @topic "updates:cluster"

  # Starts the GenServer
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def setup_mnesia_table() do
    nodes = [node() | Node.list()]
    :mnesia.create_schema(nodes)
    :mnesia.start()
    :mnesia.create_table(@table, [
      {:attributes, [:module, :state]},
      {:ram_copies, nodes}
    ])
  end

  @doc """
  Stores the state for a given module (async).
  """
  def keep_state(module, state) do
    GenServer.call(__MODULE__, {:keep_state, module, state})
  end

  @doc """
  Returns the state for a given module, or :not_found (sync).
  """
  def return_state(module) do
    GenServer.call(__MODULE__, {:return_state, module})
  end

  # GenServer callbacks

  def init(_state) do
    setup_mnesia_table()
    Phoenix.PubSub.subscribe(@pubsub, @topic)
    {:ok, nil}
  end

  def handle_cast({:keep_state, module, state}, _data) do
    :mnesia.transaction(fn ->
      :mnesia.write({@table, module, state})
    end)
    {:noreply, nil}
  end

  def handle_call({:keep_state, module, state}, _from, _data) do
    Logger.debug("Storing state for #{inspect(module)}")
    :mnesia.transaction(fn ->
      :mnesia.write({@table, module, state})
    end)
    {:reply, :ok, nil}
  end

  def handle_call({:return_state, module}, _from, _data) do
    Logger.debug("Retrieving state for #{inspect(module)}")
    result =
      case :mnesia.transaction(fn ->
             :mnesia.read({@table, module})
           end) do
        {:atomic, [{@table, ^module, state}]} -> state
        wat -> wat |> IO.inspect(label: "WAT") ; :not_found
      end

    {:reply, result, nil}
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
