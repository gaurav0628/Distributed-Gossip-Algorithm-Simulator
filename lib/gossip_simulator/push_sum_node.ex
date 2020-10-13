defmodule GossipSimulator.PushSumNode do
  @moduledoc false
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    {:ok, {[], 0, 0, 1}}
  end

  def handle_cast({:set_neighbours, neighbours}, {_nodes, count, s, w}) do
    nodes = neighbours
            |> Enum.with_index
            |> Map.new(fn {key, value} -> {value, key} end)
    {:noreply, {nodes, count, s, w}}
  end

  def handle_cast({:set_sum, sum}, {nodes, count, _s, w}) do
    {:noreply, {nodes, count, sum, w}}
  end

  def handle_cast({:push_sum, sn, wn}, {nodes, count, s, w}) do
    ns = s + sn
    nw = w + wn

    if count == 3 do
      GossipSimulator.Register.decrement_node_count()
      {:stop, :normal, nil}
    end

    ratio = s / w
    new_ratio = ns / nw
    new_count = cond  do
      abs(ratio - new_ratio) <= 0.00001 -> count + 1
      true -> count
    end

    ns = ns / 2
    nw = nw / 2

    if is_map(nodes) and map_size(nodes) > 0 do
      {_, neighbor} = Enum.random(nodes)
      GenServer.cast(neighbor, {:push_sum, ns, nw})
    end
    if !is_map(nodes) do
      GossipSimulator.Register.decrement_node_count()
    end
    {:noreply, {nodes, new_count, ns, nw}}
  end

end
