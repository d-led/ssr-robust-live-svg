defmodule BraitenbergVehiclesLiveWeb.WorldLive do
  use BraitenbergVehiclesLiveWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <svg viewBox="0 0 800 600" width="800" height="600" style="border: 0.5px solid black;">
      <circle cx="400" cy="300" r="20" fill="blue" />
    </svg>
    """
  end
end
