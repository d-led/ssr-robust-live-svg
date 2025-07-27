defmodule BallMovement do
  @callback move(movement_state :: any(), state :: map()) ::
              {cx :: integer(), cy :: integer(), dx :: integer(), dy :: integer()}
end
