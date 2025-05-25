defmodule SsrRobustLiveSvg.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ball_config = Application.get_env(:ssr_robust_live_svg, :ball, [])
    cell_config = Application.get_env(:ssr_robust_live_svg, :cell, [])
    animation_config = Application.get_env(:ssr_robust_live_svg, :animation, [])

    children = [
      SsrRobustLiveSvgWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:ssr_robust_live_svg, :dns_cluster_query) || :ignore},
      {Cluster.Supervisor, [topologies() |> IO.inspect(label: "chosen cluster config")]},
      {Phoenix.PubSub, name: SsrRobustLiveSvg.PubSub},
      SsrRobustLiveSvgWeb.Presence,
      SsrRobustLiveSvg.ClusterInfoServer,
      SsrRobustLiveSvg.VersionServer,
      SsrRobustLiveSvg.StateGuardian,
      # Horde registry and supervisor
      {Horde.Registry, [name: SsrRobustLiveSvg.HordeRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor,
       [
         name: SsrRobustLiveSvg.HordeSupervisor,
         strategy: :one_for_one,
         restart: :transient,
         distribution_strategy: Horde.UniformDistribution,
         process_redistribution: :passive,
         members: :auto,
         max_restarts: 90,
         max_seconds: 30
       ]},
      %{
        id: SsrRobustLiveSvg.ActorSupervisor,
        restart: :transient,
        start:
          {Task, :start_link,
           [
             fn ->
               ball =
                 Horde.DynamicSupervisor.start_child(
                   SsrRobustLiveSvg.HordeSupervisor,
                   Supervisor.child_spec(
                     {SsrRobustLiveSvg.Ball,
                      cell_config
                      |> Keyword.merge(animation_config)
                      |> Keyword.merge(ball_config)
                      |> Keyword.put(:movement, SsrRobustLiveSvg.MirrorJump)},
                     id: SsrRobustLiveSvg.Ball,
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
      SsrRobustLiveSvgWeb.Endpoint
    ]

    opts = [
      strategy: :one_for_one,
      name: SsrRobustLiveSvg.Supervisor,
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
    SsrRobustLiveSvgWeb.Endpoint.config_change(changed, removed)
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
