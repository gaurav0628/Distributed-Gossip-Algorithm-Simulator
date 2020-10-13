defmodule GossipSimulator.NodeCreator do
  use DynamicSupervisor
  @moduledoc false

  @module_name GossipSimulator.NodeCreator

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @module_name)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child_gossip_algorithm() do
    {_, pid} = DynamicSupervisor.start_child(@module_name, GossipSimulator.GossipAlgorithmNode)
    pid
  end

  def start_child_push_sum_algorithm() do
    {_, pid} = DynamicSupervisor.start_child(@module_name, GossipSimulator.PushSumNode)
    pid
  end


end