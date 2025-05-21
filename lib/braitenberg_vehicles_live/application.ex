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
      {Cluster.Supervisor, [topologies() |> IO.inspect(label: "chosen cluster config")]},
      {Phoenix.PubSub, name: BraitenbergVehiclesLive.PubSub},
      BraitenbergVehiclesLive.ClusterInfoServer,
      BraitenbergVehiclesLive.VersionServer,
      BraitenbergVehiclesLive.StateGuardian,
      # Horde registry and supervisor
      {Horde.Registry,
       [name: BraitenbergVehiclesLive.HordeRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor,
       [
         name: BraitenbergVehiclesLive.HordeSupervisor,
         strategy: :one_for_one,
         restart: :transient,
         distribution_strategy: Horde.UniformDistribution,
         process_redistribution: :active,
         members: :auto,
         max_restarts: 1000,
         max_seconds: 60
       ]},
      %{
        id: BraitenbergVehiclesLive.ActorSupervisor,
        restart: :transient,
        start:
          {Task, :start_link,
           [
             fn ->
               ball =
                 Horde.DynamicSupervisor.start_child(
                   BraitenbergVehiclesLive.HordeSupervisor,
                   Supervisor.child_spec(
                     {BraitenbergVehiclesLive.Ball,
                      cell_config
                      |> Keyword.merge(animation_config)
                      |> Keyword.merge(ball_config)
                      |> Keyword.put(:movement, BraitenbergVehiclesLive.MirrorJump)},
                     id: BraitenbergVehiclesLive.Ball,
                     restart: :permanent,
                     shutdown: 5000,
                     type: :worker
                   )
                 )

               # list of children
               [ball]
             end
           ]}
      },
      BraitenbergVehiclesLiveWeb.Endpoint
    ]

    opts = [
      strategy: :one_for_one,
      name: BraitenbergVehiclesLive.Supervisor,
      # Allow up to N restarts
      max_restarts: 42,
      # ...within 60 seconds
      max_seconds: 60
    ]

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BraitenbergVehiclesLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp topologies() do
    case System.get_env("ERLANG_SEED_NODES", "")
         |> String.split(",")
         |> Enum.reject(&(String.trim(&1) == ""))
         |> Enum.map(&String.to_atom/1) do
      [] ->
        [
          default: [
            strategy: Cluster.Strategy.Gossip
          ]
        ]

      seed_nodes ->
        [
          default: [
            strategy: Cluster.Strategy.Epmd,
            config: [hosts: seed_nodes]
          ]
        ]
    end
  end
end
