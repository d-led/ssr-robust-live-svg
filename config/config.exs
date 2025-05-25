# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ssr_robust_live_svg,
  generators: [timestamp_type: :utc_datetime]

config :ssr_robust_live_svg, :cell,
  width: 800,
  height: 400

version = Application.spec(:ssr_robust_live_svg, :vsn) |> to_string()

available_ball_behaviors =
  [
    SsrRobustLiveSvg.MirrorJump,
    SsrRobustLiveSvg.RandomRebound,
    SsrRobustLiveSvg.NonExistentBehavior
  ] ++
    if version == "0.1.1", do: [SsrRobustLiveSvg.RandomReboundV2NonSticky], else: []

# demo a new version with a new behavior module available

config :ssr_robust_live_svg, :available_ball_behaviors, available_ball_behaviors

config :ssr_robust_live_svg, :ball, radius: 20

config :ssr_robust_live_svg, :animation, interval: 30

# Configures the endpoint
config :ssr_robust_live_svg, SsrRobustLiveSvgWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [
      html: SsrRobustLiveSvgWeb.ErrorHTML,
      json: SsrRobustLiveSvgWeb.ErrorJSON
    ],
    layout: false
  ],
  pubsub_server: SsrRobustLiveSvg.PubSub,
  live_view: [signing_salt: "f3gG5u6X"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ssr_robust_live_svg: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  ssr_robust_live_svg: [
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

# Presence configuration
config :ssr_robust_live_svg, SsrRobustLiveSvgWeb.Presence, pubsub_server: SsrRobustLiveSvg.PubSub

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
