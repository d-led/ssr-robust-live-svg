defmodule SsrRobustLiveSvg.NodeKillSwitch do
  @moduledoc """
  Terminate the Erlang VM with a non-zero exit code.
  """

  @spec kill_node(non_neg_integer()) :: no_return()
  def kill_node(code \\ 1) do
    :init.stop(code)
    Process.sleep(1000)
    :erlang.halt(code)
  end
end
