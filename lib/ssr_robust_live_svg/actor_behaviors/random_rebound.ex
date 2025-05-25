defmodule SsrRobustLiveSvg.RandomRebound do
  defstruct []

  defimpl BallMovement, for: __MODULE__ do
    def move(_movement_state, %{
          cx: cx,
          cy: cy,
          dx: dx,
          dy: dy,
          width: width,
          height: height,
          radius: radius
        }) do
      next_cx = cx + dx
      next_cy = cy + dy

      # bug: can become zero
      randomize = fn v ->
        v + (:rand.uniform(11) - 6)
      end

      new_dx =
        cond do
          next_cx - radius <= 0 and dx < 0 -> randomize.(-dx)
          next_cx + radius >= width and dx > 0 -> randomize.(-dx)
          true -> dx
        end

      new_dy =
        cond do
          next_cy - radius <= 0 and dy < 0 -> randomize.(-dy)
          next_cy + radius >= height and dy > 0 -> randomize.(-dy)
          true -> dy
        end

      {cx + new_dx, cy + new_dy, new_dx, new_dy}
    end
  end
end
