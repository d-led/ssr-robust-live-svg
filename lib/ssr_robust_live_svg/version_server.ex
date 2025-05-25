defmodule SsrRobustLiveSvg.VersionServer do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_), do: {:ok, nil}

  def handle_call(:version, _from, state) do
    version = Application.spec(:ssr_robust_live_svg, :vsn) |> to_string()
    {:reply, version, state}
  end

  def get_version do
    GenServer.call(__MODULE__, :version)
  end
end
