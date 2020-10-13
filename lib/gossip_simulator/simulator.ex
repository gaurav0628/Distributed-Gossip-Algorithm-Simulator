defmodule GossipSimulator.Simulator do
  @moduledoc false
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    Process.send_after(self(), :start_simulation, 0)
    {:ok, args}
  end

  def create_nodes(number_of_nodes, algorithm) do
    case algorithm do
      "gossip" ->
        nodes = 1..number_of_nodes
                |> Enum.map(fn _ -> GossipSimulator.NodeCreator.start_child_gossip_algorithm() end)
        GenServer.cast(self(), {:create_nodes, number_of_nodes, nodes})
        GossipSimulator.Register.set_number_of_nodes(number_of_nodes)
        nodes
      "pushsum" ->
        nodes = 1..number_of_nodes
                |> Enum.map(fn _ -> GossipSimulator.NodeCreator.start_child_push_sum_algorithm() end)
        GenServer.cast(self(), {:create_nodes, number_of_nodes, nodes})
        GossipSimulator.Register.set_number_of_nodes(number_of_nodes)
        nodes
      _ ->
        raise "Invalid Algorithm"
    end

  end

  def handle_cast({:create_nodes, _number_of_nodes, nodes}, state) do
    {number_of_nodes, topology, algorithm, _list} = state
    {:noreply, {number_of_nodes, topology, algorithm, nodes}}
  end

  def handle_info(:start_simulation, args) do
    {number_of_nodes, topology, algorithm, _nodes} = args
    nodes = case topology do
      "full" -> create_full_topology(number_of_nodes, algorithm)
      "line" -> create_line_topology(number_of_nodes, algorithm)
      "rand2D" -> create_random_2D_topology(number_of_nodes, algorithm)
      "torus" -> create_torus_topology(number_of_nodes, algorithm)
      "honeycomb" -> create_honey_comb_topology(number_of_nodes, algorithm)
      "randhoneycomb" -> create_random_honey_comb_topology(number_of_nodes, algorithm)
      _ -> raise "Invalid Algorithm"
    end

    start_time = Time.utc_now()
    GossipSimulator.Register.set_start_time(start_time)
    case algorithm do
      "gossip" ->
        GenServer.cast(Enum.random(nodes), {:spread_rumor, "Elixir"})
      "pushsum" ->
        Enum.with_index(nodes)
        |> Enum.each(fn {x, i} -> GenServer.cast(x, {:set_sum, i + 1}) end)
        GenServer.cast(Enum.random(nodes), {:push_sum, 0, 0})
      _ ->
        raise "Invalid Algorithm"
    end
    {:noreply, {length(nodes), topology, algorithm, nodes}}
  end

  def create_full_topology(number_of_nodes, algorithms) do
    nodes = create_nodes(number_of_nodes, algorithms)
    Enum.each(
      nodes,
      fn x ->
        GenServer.cast(x, {:set_neighbours, List.delete(nodes, x)})
      end
    )
    nodes
  end

  def create_line_topology(number_of_nodes, algorithms) do
    nodes = create_nodes(number_of_nodes, algorithms)

    Enum.with_index(nodes)
    |> Enum.each(
         fn {pid, i} ->
           cond do
             i == 0 ->
               GenServer.cast(pid, {:set_neighbours, [Enum.at(nodes, 1)]})

             i == length(nodes) - 1 ->
               GenServer.cast(pid, {:set_neighbours, [Enum.at(nodes, i - 1)]})

             true ->
               GenServer.cast(pid, {:set_neighbours, [Enum.at(nodes, i - 1), Enum.at(nodes, i + 1)]})
           end
         end
       )
    nodes
  end

  def create_random_honey_comb_topology(number_of_nodes, algorithms) do
    w = round(:math.pow(number_of_nodes, 1 / 2))
    nodes = create_nodes(w * w + w + 1, algorithms)
    Enum.each(
      0..w,
      fn i ->
        Enum.each(
          i * w + 1..w * (i + 1),
          fn j ->
            #random_index = :rand.uniform(new_number_of_nodes)
            cond do
              (j == 1 || j == w) and i == 0 ->
                random_index = :rand.uniform((i + 1) * w)
                GenServer.cast(
                  Enum.at(nodes, j),
                  {:set_neighbours, [Enum.at(nodes, j + w), Enum.at(nodes, random_index)]}
                )
              i == 0 ->
                if rem(j, 2) == 0 do
                  random_index = :rand.uniform((i + 1) * w)
                  GenServer.cast(
                    Enum.at(nodes, j),
                    {:set_neighbours, [Enum.at(nodes, j + 1), Enum.at(nodes, j + w), Enum.at(nodes, random_index)]}
                  )
                else
                  random_index = :rand.uniform((i + 1) * w)
                  GenServer.cast(
                    Enum.at(nodes, j),
                    {:set_neighbours, [Enum.at(nodes, j - 1), Enum.at(nodes, j + w), Enum.at(nodes, random_index)]}
                  )
                end
              i == w and (j == i * w + 1 || j == w * (i + 1)) ->
                random_index = :rand.uniform(i * w)
                GenServer.cast(
                  Enum.at(nodes, j),
                  {:set_neighbours, [Enum.at(nodes, j - w), Enum.at(nodes, random_index)]}
                )
              i == w ->
                cond do
                  rem(j, 2) == 0 ->
                    random_index = :rand.uniform(i * w)
                    GenServer.cast(
                      Enum.at(nodes, j),
                      {:set_neighbours, [Enum.at(nodes, j + 1), Enum.at(nodes, j - w), Enum.at(nodes, random_index)]}
                    )
                  true ->
                    random_index = :rand.uniform(i * w)
                    GenServer.cast(
                      Enum.at(nodes, j),
                      {:set_neighbours, [Enum.at(nodes, j - 1), Enum.at(nodes, j - w), Enum.at(nodes, random_index)]}
                    )
                end
              rem(i, 2) != 0 ->
                random_index = :rand.uniform(i * w)
                if rem(j, 2) == 0 do
                  GenServer.cast(
                    Enum.at(nodes, j),
                    {
                      :set_neighbours,
                      [
                        Enum.at(nodes, j - 1),
                        Enum.at(nodes, j - w),
                        Enum.at(nodes, j + w),
                        Enum.at(nodes, random_index)
                      ]
                    }
                  )
                else
                  random_index = :rand.uniform(i * w)
                  GenServer.cast(
                    Enum.at(nodes, j),
                    {
                      :set_neighbours,
                      [
                        Enum.at(nodes, j + 1),
                        Enum.at(nodes, j - w),
                        Enum.at(nodes, j + w),
                        Enum.at(nodes, random_index)
                      ]
                    }
                  )
                end
              rem(i, 2) == 0 ->
                cond do
                  j == i * w + 1 || j == w * (i + 1) ->
                    random_index = :rand.uniform(i * w)
                    GenServer.cast(
                      Enum.at(nodes, j),
                      {:set_neighbours, [Enum.at(nodes, j - w), Enum.at(nodes, j + w), Enum.at(nodes, random_index)]}
                    )
                  rem(j, 2) != 0 ->
                    random_index = :rand.uniform(i * w)
                    GenServer.cast(
                      Enum.at(nodes, j),
                      {
                        :set_neighbours,
                        [
                          Enum.at(nodes, j - 1),
                          Enum.at(nodes, j - w),
                          Enum.at(nodes, j + w),
                          Enum.at(nodes, random_index)
                        ]
                      }
                    )
                  true ->
                    random_index = :rand.uniform(i * w)
                    GenServer.cast(
                      Enum.at(nodes, j),
                      {
                        :set_neighbours,
                        [
                          Enum.at(nodes, j + 1),
                          Enum.at(nodes, j - w),
                          Enum.at(nodes, j + w),
                          Enum.at(nodes, random_index)
                        ]
                      }
                    )
                end
              true -> ""
            end
          end
        )
      end
    )
    GossipSimulator.Register.set_number_of_nodes(w * w)
    nodes
  end

  def create_honey_comb_topology(number_of_nodes, algorithms) do
    w = round(:math.pow(number_of_nodes, 1 / 2))
    nodes = create_nodes(w * w + w + 1, algorithms)
    Enum.each(
      0..w,
      fn i ->
        Enum.each(
          i * w + 1..w * (i + 1),
          fn j ->
            cond do
              (j == 1 || j == w) and i == 0 ->
                GenServer.cast(Enum.at(nodes, j), {:set_neighbours, [Enum.at(nodes, j + w)]})
              i == 0 ->
                if rem(j, 2) == 0 do
                  GenServer.cast(Enum.at(nodes, j), {:set_neighbours, [Enum.at(nodes, j + 1), Enum.at(nodes, j + w)]})
                else
                  GenServer.cast(Enum.at(nodes, j), {:set_neighbours, [Enum.at(nodes, j - 1), Enum.at(nodes, j + w)]})
                end
              i == w and (j == i * w + 1 || j == w * (i + 1)) ->
                GenServer.cast(Enum.at(nodes, j), {:set_neighbours, [Enum.at(nodes, j - w)]})
              i == w ->
                cond do
                  rem(j, 2) == 0 ->
                    GenServer.cast(Enum.at(nodes, j), {:set_neighbours, [Enum.at(nodes, j + 1), Enum.at(nodes, j - w)]})
                  true ->
                    GenServer.cast(Enum.at(nodes, j), {:set_neighbours, [Enum.at(nodes, j - 1), Enum.at(nodes, j - w)]})
                end
              rem(i, 2) != 0 ->
                if rem(j, 2) == 0 do
                  GenServer.cast(
                    Enum.at(nodes, j),
                    {:set_neighbours, [Enum.at(nodes, j - 1), Enum.at(nodes, j - w), Enum.at(nodes, j + w)]}
                  )
                else
                  GenServer.cast(
                    Enum.at(nodes, j),
                    {:set_neighbours, [Enum.at(nodes, j + 1), Enum.at(nodes, j - w), Enum.at(nodes, j + w)]}
                  )
                end
              rem(i, 2) == 0 ->
                cond do
                  j == i * w + 1 || j == w * (i + 1) ->
                    GenServer.cast(Enum.at(nodes, j), {:set_neighbours, [Enum.at(nodes, j - w), Enum.at(nodes, j + w)]})
                  rem(j, 2) != 0 ->
                    GenServer.cast(
                      Enum.at(nodes, j),
                      {:set_neighbours, [Enum.at(nodes, j - 1), Enum.at(nodes, j - w), Enum.at(nodes, j + w)]}
                    )
                  true ->
                    GenServer.cast(
                      Enum.at(nodes, j),
                      {:set_neighbours, [Enum.at(nodes, j + 1), Enum.at(nodes, j - w), Enum.at(nodes, j + w)]}
                    )
                end
              true -> ""
            end
          end
        )
      end
    )
    GossipSimulator.Register.set_number_of_nodes(w * w)
    nodes
  end

  def create_torus_topology(number_of_nodes, algorithm) do
    w = round(:math.pow(number_of_nodes, 1 / 3))
    nodes = create_nodes(w * w * w, algorithm)
    s = length(nodes)
    w_square = w * w
    w_cube = w * w * w
    #staring node
    GenServer.cast(
      Enum.at(nodes, 0),
      {
        :set_neighbours,
        [
          Enum.at(nodes, 1),
          Enum.at(nodes, w),
          Enum.at(nodes, w_square - w),
          Enum.at(nodes, w_cube - w_square),
          Enum.at(nodes, w - 1),
          Enum.at(nodes, w_square)
        ]
      }
    )

    #x end
    GenServer.cast(
      Enum.at(nodes, w - 1),
      {
        :set_neighbours,
        [
          Enum.at(nodes, w - 2),
          Enum.at(nodes, 0),
          Enum.at(nodes, w - 1 + w),
          Enum.at(nodes, w_square - 1 + w),
          Enum.at(nodes, w_square - 1),
          Enum.at(nodes, w_cube - w_square + w - 1)
        ]
      }
    )

    #y end
    GenServer.cast(
      Enum.at(nodes, w_square - w),
      {
        :set_neighbours,
        [
          Enum.at(nodes, w_square - w + 1),
          Enum.at(nodes, w_square - 1),
          Enum.at(nodes, w_square - w - w),
          Enum.at(nodes, w_square - w + w_square),
          Enum.at(nodes, 0),
          Enum.at(nodes, w_cube - w_square + w_square - w)
        ]
      }
    )

    #y upper end right
    GenServer.cast(
      Enum.at(nodes, w_square - 1),
      {
        :set_neighbours,
        [
          Enum.at(nodes, w_square - 2),
          Enum.at(nodes, w_square - w),
          Enum.at(nodes, w_square + w_square - 1),
          Enum.at(nodes, w_square - w - 1),
          Enum.at(nodes, w - 1),
          Enum.at(nodes, w_cube - 1)
        ]
      }
    )

    #z end
    GenServer.cast(
      Enum.at(nodes, w_cube - w_square),
      {
        :set_neighbours,
        [
          Enum.at(nodes, 0),
          Enum.at(nodes, w_cube - w_square + 1),
          Enum.at(nodes, w_cube - w_square + w - 1),
          Enum.at(nodes, w_cube - w_square - w_square),
          Enum.at(nodes, w_cube - w_square + w),
          Enum.at(nodes, w_cube - w_square + w_square - w)
        ]
      }
    )

    #z lower other end
    GenServer.cast(
      Enum.at(nodes, w_cube - w_square + w - 1),
      {
        :set_neighbours,
        [
          Enum.at(nodes, w_cube - w_square + w - 2),
          Enum.at(nodes, w_cube - w_square + w + w - 1),
          Enum.at(nodes, w - 1),
          Enum.at(nodes, w_cube - w_square - w_square + w - 1),
          Enum.at(nodes, w_cube - w_square),
          Enum.at(nodes, w_cube - 1)
        ]
      }
    )

    # last node
    GenServer.cast(
      Enum.at(nodes, w_cube - 1),
      {
        :set_neighbours,
        [
          Enum.at(nodes, w_cube - w_square + w - 1),
          Enum.at(nodes, w_square - 1),
          Enum.at(nodes, w_cube - w_square - 1),
          Enum.at(nodes, w_cube - w - 1),
          Enum.at(nodes, w_cube - 2),
          Enum.at(nodes, w_cube - w)
        ]
      }
    )

    # z left top
    GenServer.cast(
      Enum.at(nodes, w_cube - w),
      {
        :set_neighbours,
        [
          Enum.at(nodes, w_cube - 1),
          Enum.at(nodes, w_square - w),
          Enum.at(nodes, w_cube - w_square),
          Enum.at(nodes, w_cube - w + 1),
          Enum.at(nodes, w_cube - w_square - w),
          Enum.at(nodes, w_cube - w - w)
        ]
      }
    )

    # edges start
    Enum.each(
      1..w - 2,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x + w_cube - w_square),
              Enum.at(nodes, x + w_square - w)
            ]
          }
        )
      end
    )

    Enum.each(
      w_cube - w_square + 1..w_cube - w_square + w - 2,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x - w_cube + w_square),
              Enum.at(nodes, x + w_square - w)
            ]
          }
        )
      end
    )

    Enum.each(
      w_square - w + 1..w_square - 2,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x - w),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x + w_cube - w_square),
              Enum.at(nodes, x - w_square + w)
            ]
          }
        )
      end
    )


    Enum.each(
      w_cube - w + 1..w_cube - 2,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x - w),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x - w_cube + w_square),
              Enum.at(nodes, x - w_square + w)
            ]
          }
        )
      end
    )


    Enum.map_every(
      w..w_square - w - w,
      w,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x + w_cube - w_square),
              Enum.at(nodes, x + w - 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w - 1 + w..w_square - 1 - w,
      w,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w),
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x + w_cube - w_square),
              Enum.at(nodes, x - w + 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w_cube - w_square + w..w_cube - w - w,
      w,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x - w_cube + w_square),
              Enum.at(nodes, x + w - 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w_cube - w_square + w - 1 + w..w_cube - 1 - w,
      w,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w),
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x - w_cube + w_square),
              Enum.at(nodes, x - w + 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w_square..w_cube - w_square - w_square,
      w_square,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x + w_square - w),
              Enum.at(nodes, x + w - 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w - 1 + w_square..w_cube - w_square + w - 1 - w_square,
      w_square,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x + w),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x + w_square - w),
              Enum.at(nodes, x - w + 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w_square - w + w_square..w_cube - w - w_square,
      w_square,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x + 1),
              Enum.at(nodes, x - w),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x - w_square + w),
              Enum.at(nodes, x + w + 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w_square - 1 + w_square..s - 1 - w_square,
      w_square,
      fn x ->
        GenServer.cast(
          Enum.at(nodes, x),
          {
            :set_neighbours,
            [
              Enum.at(nodes, x - w_square),
              Enum.at(nodes, x - 1),
              Enum.at(nodes, x - w),
              Enum.at(nodes, x + w_square),
              Enum.at(nodes, x - w_square + w),
              Enum.at(nodes, x - w + 1)
            ]
          }
        )
      end
    )

    Enum.map_every(
      w + 1..w_square - w - w + 1,
      w,
      fn x ->
        Enum.each(
          x..x + w - 3,
          fn i ->
            GenServer.cast(
              Enum.at(nodes, i),
              {
                :set_neighbours,
                [
                  Enum.at(nodes, i - 1),
                  Enum.at(nodes, i + 1),
                  Enum.at(nodes, i - w),
                  Enum.at(nodes, i + w),
                  Enum.at(nodes, i + w_square),
                  Enum.at(nodes, i + w_cube - w_square)
                ]
              }
            )
          end
        )
      end
    )

    Enum.map_every(
      w_cube - w_square + w + 1..w_cube - w - w + 1,
      w,
      fn x ->
        Enum.each(
          x..x + w - 3,
          fn i ->
            GenServer.cast(
              Enum.at(nodes, i),
              {
                :set_neighbours,
                [
                  Enum.at(nodes, i - 1),
                  Enum.at(nodes, i + 1),
                  Enum.at(nodes, i - w),
                  Enum.at(nodes, i + w),
                  Enum.at(nodes, i - w_square),
                  Enum.at(nodes, i - w_cube + w_square)
                ]
              }
            )
          end
        )
      end
    )

    #top
    Enum.map_every(
      w_square + 1..w_cube - w_square - w_square + 1,
      w_square,
      fn x ->
        Enum.each(
          x..x + w - 3,
          fn i ->
            GenServer.cast(
              Enum.at(nodes, i),
              {
                :set_neighbours,
                [
                  Enum.at(nodes, i - 1),
                  Enum.at(nodes, i + 1),
                  Enum.at(nodes, i - w_square),
                  Enum.at(nodes, i + w_square),
                  Enum.at(nodes, i + w),
                  Enum.at(nodes, i - w_square + w)
                ]
              }
            )
          end
        )
      end
    )

    Enum.map_every(
      w_square - w + w_square + 1..w_cube - w - w_square + 1,
      w_square,
      fn x ->
        Enum.each(
          x..x + w - 3,
          fn i ->
            GenServer.cast(
              Enum.at(nodes, i),
              {
                :set_neighbours,
                [
                  Enum.at(nodes, i - 1),
                  Enum.at(nodes, i + 1),
                  Enum.at(nodes, i - w_square),
                  Enum.at(nodes, i + w_square),
                  Enum.at(nodes, i - w),
                  Enum.at(nodes, i + w_square - w)
                ]
              }
            )
          end
        )
      end
    )

    Enum.map_every(
      w + w_square..w_square - w - w + w_square,
      w,
      fn x ->
        Enum.map_every(
          x..x + (w_square * (w - 3)),
          w_square,
          fn i ->
            GenServer.cast(
              Enum.at(nodes, i),
              {
                :set_neighbours,
                [
                  Enum.at(nodes, i - w),
                  Enum.at(nodes, i + w),
                  Enum.at(nodes, i - w_square),
                  Enum.at(nodes, i + w_square),
                  Enum.at(nodes, i + 1),
                  Enum.at(nodes, i + w - 1)
                ]
              }
            )
          end
        )
      end
    )

    Enum.map_every(
      w + w_square + w - 1..w_square - w + w_square - 1,
      w,
      fn x ->
        Enum.map_every(
          x..x + (w_square * (w - 3)),
          w_square,
          fn i ->
            GenServer.cast(
              Enum.at(nodes, i),
              {
                :set_neighbours,
                [
                  Enum.at(nodes, i - w),
                  Enum.at(nodes, i + w),
                  Enum.at(nodes, i - w_square),
                  Enum.at(nodes, i + w_square),
                  Enum.at(nodes, i - 1),
                  Enum.at(nodes, i - w + 1)
                ]
              }
            )
          end
        )
      end
    )

    Enum.map_every(
      w + 1 + w_square..w_cube - w_square + w + 1 - w_square,
      w_square,
      fn x ->
        Enum.map_every(
          x..x + (w * (w - 3)),
          w,
          fn y ->
            Enum.each(
              y..y + w - 3,
              fn i ->
                GenServer.cast(
                  Enum.at(nodes, i),
                  {
                    :set_neighbours,
                    [
                      Enum.at(nodes, i - 1),
                      Enum.at(nodes, i + 1),
                      Enum.at(nodes, i - w),
                      Enum.at(nodes, i + w),
                      Enum.at(nodes, i - w_square),
                      Enum.at(nodes, i + w_square)
                    ]
                  }
                )
              end
            )
          end
        )
      end
    )
    nodes
  end


  def create_random_2D_topology(number_of_nodes, algorithm) do
    w = round(:math.sqrt(number_of_nodes))
    nodes = create_nodes(w * w, algorithm)
    points = Enum.map(
      nodes,
      fn _ ->
        x = :rand.uniform()
        y = :rand.uniform()
        {x, y}
      end
    )
    Enum.with_index(nodes)
    |> Enum.each(
         fn {pid, i} ->

           {a, b} = Enum.at(points, i)
           neigh = Enum.with_index(points)
                   |> Enum.map(
                        fn {{x, y}, k} ->
                          dx = a - x
                          dy = b - y
                          if (dx != 0) and (dy != 0) and (:math.sqrt((dx * dx) + (dy * dy)) <= 0.1) do
                            Enum.at(nodes, k)
                          end
                        end
                      )
           GenServer.cast(pid, {:set_neighbours, Enum.filter(neigh, &!is_nil(&1))})
         end
       )
    nodes
  end
end
