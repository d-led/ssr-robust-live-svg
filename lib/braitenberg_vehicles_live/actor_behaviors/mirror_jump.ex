defmodule BraitenbergVehiclesLive.MirrorJump do
  # stateless for now

  defimpl BallMovement, for: Map do
    def move(%{
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

      new_dx =
        cond do
          next_cx - radius <= 0 and dx < 0 -> -dx
          next_cx + radius >= width and dx > 0 -> -dx
          true -> dx
        end

      new_dy =
        cond do
          next_cy - radius <= 0 and dy < 0 -> -dy
          next_cy + radius >= height and dy > 0 -> -dy
          true -> dy
        end

      {cx + new_dx, cy + new_dy, new_dx, new_dy}
    end
  end
end
