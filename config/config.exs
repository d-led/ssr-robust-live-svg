# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :braitenberg_vehicles_live,
  generators: [timestamp_type: :utc_datetime]

config :braitenberg_vehicles_live, :cell,
  width: 800,
  height: 600

config :braitenberg_vehicles_live, :available_ball_behaviors, [
  BraitenbergVehiclesLive.MirrorJump,
  BraitenbergVehiclesLive.RandomRebound,
  BraitenbergVehiclesLive.NonExistentBehavior
]

config :braitenberg_vehicles_live, :ball, radius: 20

config :braitenberg_vehicles_live, :animation, interval: 30

# Configures the endpoint
config :braitenberg_vehicles_live, BraitenbergVehiclesLiveWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [
      html: BraitenbergVehiclesLiveWeb.ErrorHTML,
      json: BraitenbergVehiclesLiveWeb.ErrorJSON
    ],
    layout: false
  ],
  pubsub_server: BraitenbergVehiclesLive.PubSub,
  live_view: [signing_salt: "f3gG5u6X"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  braitenberg_vehicles_live: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  braitenberg_vehicles_live: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
