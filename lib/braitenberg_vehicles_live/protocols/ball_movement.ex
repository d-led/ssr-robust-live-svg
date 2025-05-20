defprotocol BallMovement do
  @spec move(movement_state :: any(), state :: map()) ::
          {cx :: integer(), cy :: integer(), dx :: integer(), dy :: integer()}
  def move(movement_state, state)
end
