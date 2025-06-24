defmodule SsrRobustLiveSvgWeb.CircleComponent do
  use Phoenix.Component

  @doc """
  Renders an SVG circle.

  ## Assigns

    * `:cx` - The x-coordinate of the center.
    * `:cy` - The y-coordinate of the center.
    * `:r` - The radius.
    * `:fill` - The fill color (optional, defaults to "blue").
    * `:stroke` - The stroke color (optional, defaults to nil).
  """
  attr :cx, :any, required: true
  attr :cy, :any, required: true
  attr :r, :any, required: true
  attr :fill, :string, default: "blue"
  attr :stroke, :string, default: nil

  def circle(assigns) do
    ~H"""
    <circle
      cx={@cx}
      cy={@cy}
      r={@r}
      fill={@fill}
      stroke={@stroke}
      stroke-width={if @stroke, do: "1", else: nil}
    />
    """
  end
end
