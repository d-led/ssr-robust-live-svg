defmodule SsrRobustLiveSvg.BehaviorModules do
  use GenServer

  require Logger

  def start_link(modules) do
    GenServer.start_link(__MODULE__, modules, name: __MODULE__)
  end

  def init(modules) do
    my_modules = load_modules(modules) |> IO.inspect(label: "Loaded modules")

    Task.start(fn ->
      Process.sleep(300)
      __MODULE__.spread_modules()
    end)

    {:ok, %{new_modules: %{}, my_modules: my_modules}}
  end

  def load_modules(modules) do
    modules
    # keep the bug for the demo
    |> Enum.reject(&(&1 == SsrRobustLiveSvg.NonExistentBehavior))
    |> Enum.map(fn mod ->
      Code.ensure_loaded!(mod)
      {mod, :code.get_object_code(mod)}
    end)
    |> Enum.into(%{})
    # put the buggy module deliberately
    |> Map.put(
      SsrRobustLiveSvg.NonExistentBehavior,
      {SsrRobustLiveSvg.NonExistentBehavior,
       :code.get_object_code(SsrRobustLiveSvg.NonExistentBehavior)}
    )
  end

  # Public API to fetch all available modules (returns {my_modules, new_modules} separately)
  def get_all_available_modules do
    GenServer.call(__MODULE__, :get_all_available_modules)
  end

  # Public API to handle incoming module code
  def incoming_module(from_node, module_name, object_code) do
    GenServer.call(__MODULE__, {:incoming_module, from_node, module_name, object_code})
  end

  # Public API to spread all known modules
  def spread_modules do
    # wait a while to not miss susbcriptions on freshly started nodes
    GenServer.call(__MODULE__, :spread_modules)
  end

  # GenServer callback to handle fetching all modules
  def handle_call(:get_all_available_modules, _from, state) do
    my_modules = Map.keys(state.my_modules)
    new_modules = Map.keys(state.new_modules)
    {:reply, {my_modules, new_modules}, state}
  end

  def handle_call({:incoming_module, from_node, module_name, {mod, bin, file}}, _from, state) do
    if from_node == Node.self() do
      {:reply, :ignored, state}
    else
      known =
        Map.has_key?(state.my_modules, module_name) or
          Map.has_key?(state.new_modules, module_name)

      if known do
        Logger.info("Module #{module_name} is already loaded, skipping.")
        {:reply, :already_loaded, state}
      else
        case :code.load_binary(mod, file, bin) do
          {:module, ^mod} ->
            Logger.info("Loaded new module: #{module_name} / #{file}")

            Phoenix.PubSub.local_broadcast(
              SsrRobustLiveSvg.PubSub,
              "modules:new:local",
              {:new_module_local, module_name}
            )

            new_modules = Map.put(state.new_modules, module_name, {mod, bin, file})
            {:reply, :loaded, %{state | new_modules: new_modules}}

          {:error, reason} ->
            Logger.error("Failed to load new module #{module_name}: #{inspect(reason)}")
            {:reply, {:error, reason}, state}

          other ->
            Logger.error("Unexpected result loading new module #{module_name}: #{inspect(other)}")
            {:reply, {:error, other}, state}
        end
      end
    end
  end

  def handle_call({:incoming_module, from_node, module_name, broken_module}, _from, state) do
    if from_node == Node.self() do
      {:reply, :ignored, state}
    else
      Logger.error(
        "Unexpected incoming module definition for #{module_name}: #{inspect(broken_module)}"
      )

      {:reply, {:error, broken_module}, state}
    end
  end

  def handle_call(:spread_modules, _from, state) do
    all_modules =
      Map.merge(state.my_modules, state.new_modules)

    my_node = Node.self()

    Enum.each(all_modules, fn {module_name, object_code} ->
      Phoenix.PubSub.broadcast(
        SsrRobustLiveSvg.PubSub,
        "module:spread",
        {:got_module, my_node, module_name, object_code}
      )
    end)

    Logger.info("Spread #{map_size(all_modules)} modules to all nodes.")

    {:reply, :ok, state}
  end
end
