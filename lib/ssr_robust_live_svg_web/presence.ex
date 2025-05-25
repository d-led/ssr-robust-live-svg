defmodule SsrRobustLiveSvgWeb.Presence do
  use Phoenix.Presence,
    otp_app: :ssr_robust_live_svg,
    pubsub_server: SsrRobustLiveSvg.PubSub
end
