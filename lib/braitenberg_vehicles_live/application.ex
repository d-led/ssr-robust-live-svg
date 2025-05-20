defmodule BraitenbergVehiclesLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ball_config = Application.get_env(:braitenberg_vehicles_live, :ball, [])
    cell_config = Application.get_env(:braitenberg_vehicles_live, :cell, [])
    animation_config = Application.get_env(:braitenberg_vehicles_live, :animation, [])

    children = [
      BraitenbergVehiclesLiveWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:braitenberg_vehicles_live, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BraitenbergVehiclesLive.PubSub},
      {BraitenbergVehiclesLive.Ball,
       cell_config
       |> Keyword.merge(animation_config)
       |> Keyword.merge(ball_config)},
      # Start to serve requests, typically the last entry
      BraitenbergVehiclesLiveWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BraitenbergVehiclesLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BraitenbergVehiclesLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
