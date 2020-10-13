defmodule GossipSimulator.Register do
  @moduledoc false

  use GenServer

  @module_name GossipSimulator.Register

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: @module_name)
  end

  def init(_opts) do
    {:ok, {0, 0, 0, nil}}
  end

  def decrement_node_count() do
    GenServer.cast(@module_name, :decrement_node_count)
  end

  def set_start_time(start_time) do
    GenServer.cast(@module_name, {:started, start_time})
  end

  def set_number_of_nodes(number_of_nodes) do
    GenServer.cast(@module_name, {:set_number_of_nodes, number_of_nodes})
  end

  def handle_cast({:set_number_of_nodes, number_of_nodes}, state) do
    {_, count, failed, start_time} = state
    {:noreply, {number_of_nodes, count, failed, start_time}}
  end

  def handle_cast({:started, set_start_time}, {non, count, failed, _start_time}) do
    {:noreply, {non, count, failed, set_start_time}}
  end

  def handle_cast(:decrement_node_count, {number_of_nodes, count, failed, start_time}) do
    if number_of_nodes == count + 1 do
      IO.puts "Converge time #{Time.diff(start_time, Time.utc_now(), :millisecond)}"
      System.halt(0)
    end
    {:noreply, {number_of_nodes, count + 1, failed, start_time}}
  end
end
