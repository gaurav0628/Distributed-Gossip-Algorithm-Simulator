defmodule GossipSimulator.GossipAlgorithmNode do
  use GenServer, restart: :temporary

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    {:ok, {[], 0, nil}}
  end

  def handle_cast({:set_neighbours, neighbours}, _state) do
    nodes = neighbours
            |> Enum.with_index
            |> Map.new(fn {key, value} -> {value, key} end)
    {:noreply, {nodes, 0, nil}}
  end

  def handle_cast({:send_message, _message}, state) do
    {neighbours, count, message} = state
    if map_size(neighbours) > 0 do
      {_, random_neighbor} = Enum.random(neighbours)
      GenServer.cast(random_neighbor, {:spread_rumor, message})
    end

    GenServer.cast(self(), {:send_message, message})
    {:noreply, {neighbours, count, message}}
  end

  def handle_cast({:spread_rumor, message}, state) do
    {neighbours, count, _} = state
    if count == 0 do
      GenServer.cast(self(), {:send_message, message})
    end
    if count == 10 do
      GossipSimulator.Register.decrement_node_count()
      {:stop, :normal, nil}
    end
    {:noreply, {neighbours, count + 1, message}}
  end


end