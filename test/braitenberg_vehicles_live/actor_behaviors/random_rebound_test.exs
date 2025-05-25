defmodule BraitenbergVehiclesLive.RandomReboundTest do
  use ExUnit.Case

  # switch to this module to show the bug
  # @random_rebound_module BraitenbergVehiclesLive.RandomRebound
  @random_rebound_module BraitenbergVehiclesLive.RandomReboundV2NonSticky

  defp move_ball(opts) do
    # Provide defaults and allow overrides
    state =
      %{
        cx: 50,
        cy: 50,
        dx: 5,
        dy: 5,
        width: 100,
        height: 100,
        radius: 10
      }
      |> Map.merge(opts)

    # The movement struct is not used in logic, so just pass @random_rebound_module
    BallMovement.move(struct(@random_rebound_module), state)
  end

  test "moves normally when not near any wall" do
    {cx, cy, dx, dy} = move_ball(%{cx: 50, cy: 50, dx: 5, dy: 5})
    assert is_number(cx)
    assert is_number(cy)
    assert dx == 5
    assert dy == 5
  end

  test "bounces and randomizes dx at left wall" do
    # Place ball at left wall, moving left
    {_, _, dx, _} = move_ball(%{cx: 10, dx: -5, radius: 10})
    assert dx != -5
    assert dx != 0
  end

  test "bounces and randomizes dx at right wall" do
    # Place ball at right wall, moving right
    {_, _, dx, _} = move_ball(%{cx: 90, dx: 5, width: 100, radius: 10})
    assert dx != 5
    assert dx != 0
  end

  @tag :skip
  test "bounces and randomizes dy at top wall" do
    # Place ball at top wall, moving up
    {_, _, _, dy} = move_ball(%{cy: 10, dy: -5, radius: 10})
    assert dy != -5
    assert dy != 0
  end

  test "bounces and randomizes dy at bottom wall" do
    # Place ball at bottom wall, moving down
    {_, _, _, dy} = move_ball(%{cy: 90, dy: 5, height: 100, radius: 10})
    assert dy != 5
    assert dy != 0
  end

  test "does not randomize dx if not hitting left or right wall" do
    {_, _, dx, _} = move_ball(%{cx: 50, dx: 5, width: 100, radius: 10})
    assert dx == 5
  end

  test "does not randomize dy if not hitting top or bottom wall" do
    {_, _, _, dy} = move_ball(%{cy: 50, dy: 5, height: 100, radius: 10})
    assert dy == 5
  end

  test "randomize never returns zero" do
    # Run multiple times to check randomize never returns zero
    Enum.each(1..100, fn _ ->
      {_, _, dx, dy} = move_ball(%{cx: 10, dx: -5, cy: 10, dy: -5, radius: 10})
      refute dx == 0
      refute dy == 0
    end)
  end
end
