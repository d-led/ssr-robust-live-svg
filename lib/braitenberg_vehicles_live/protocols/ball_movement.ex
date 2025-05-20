defprotocol BallMovement do
  @spec move(state :: map()) ::
          {cx :: integer(), cy :: integer(), dx :: integer(), dy :: integer()}
  def move(state)
end
