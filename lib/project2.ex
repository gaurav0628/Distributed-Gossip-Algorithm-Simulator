defmodule GossipSimulator do
  @moduledoc """
  Documentation for Project2.
  """
  def start(_type, _args) do
    start_time = System.monotonic_time(:millisecond)
    args = System.argv()
    number_of_nodes = String.to_integer(Enum.at(args, 0))
    topology = Enum.at(args, 1)
    algorithm = Enum.at(args, 2)

    children = [
      GossipSimulator.Register,
      {GossipSimulator.Simulator, {number_of_nodes, topology, algorithm, []}},
      GossipSimulator.NodeCreator
    ]

    opts = [strategy: :one_for_one, name: GossipSimulator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
