defmodule SsrRobustLiveSvgWeb.CircleComponent do
  use Phoenix.Component

  @doc """
  Renders an SVG circle.

  ## Assigns

    * `:cx` - The x-coordinate of the center.
    * `:cy` - The y-coordinate of the center.
    * `:r` - The radius.
    * `:fill` - The fill color (optional, defaults to "blue").
  """
  attr :cx, :any, required: true
  attr :cy, :any, required: true
  attr :r, :any, required: true
  attr :fill, :string, default: "blue"

  def circle(assigns) do
    ~H"""
    <circle cx={@cx} cy={@cy} r={@r} fill={@fill} />
    """
  end
end
