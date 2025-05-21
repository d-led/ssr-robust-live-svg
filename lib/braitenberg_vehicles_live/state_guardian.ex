defmodule BraitenbergVehiclesLive.StateGuardian do
  use GenServer

  # Starts the GenServer
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Stores the state for a given module.
  """
  def keep_state(module, state) do
    GenServer.cast(__MODULE__, {:keep_state, module, state})
  end

  @doc """
  Returns the state for a given module, or :not_found.
  """
  def return_state(module) do
    GenServer.call(__MODULE__, {:return_state, module})
  end

  # GenServer callbacks

  def init(state) do
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
end
