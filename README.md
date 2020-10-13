# Distributed-Gossip-Algorithm-Simulator
A distributed application that exhibits Gossip and PushSum Algorithm for different topologies.

** PROBLEM STATEMENT : **

As described in class Gossip type algorithms can be used both for group communication and for aggregate computation. The goal of this project is to
determine the convergence of such algorithms through a simulator based on actors written in Elixir. Since actors in Elixir are fully asynchronous, the particular type of Gossip implemented is the so-called Asynchronous Gossip. Gossip Algorithm for information propagation: The Gossip algorithm involves the
following:

• Starting: A participant(actor) it told/sent a rumor(fact) by the main process
• Step: Each actor selects a random neighbor and tells it the rumor
• Termination: Each actor keeps track of rumors and how many times it has
heard the rumor. It stops transmitting once it has heard the rumor 10 times
(10 is arbitrary, you can play with other numbers or other stopping criteria).

Push-Sum algorithm for sum computation:

  • State: Each actor Ai maintains two quantities: s and w. Initially, s = xi = i (that
  is actor number i has value i, play with other distribution if you so desire) and
  w = 1.
  • Starting: Ask one of the actors to start from the main process.
  • Receive: Messages sent and received are pairs of the form (s, w). Upon
  receive, an actor should add received pair to its own corresponding values.
  Upon receive, each actor selects a random neighbor and sends it a message.
  • Send: When sending a message to another actor, half of s and w is kept by
  the sending actor and half is placed in the message.
  • Sum estimate: At any given moment of time, the sum estimate is s/w where
  s and w are the current values of an actor.
  • Termination: If an actor ratio s/w did not change more than 10-10 in 3
  consecutive rounds the actor terminates. WARNING: the values s and w
  independently never converge, only the ratio does.
  • Topologies : Line, Full, Random 2D, Honeycomb, Honeycomb with a neighbor, 3D Torus
  

** STEPS TO RUN :**

1. Pull the code to your local machine. Ensure that the machine has Elixir installed and is working fine.
2. Go to the root directory of pulled code, and open terminal.
3. All the below mentioned algorithms and topologies are working. Please use following command to run the project :

	mix run --no-halt project2.ex nodes topology algorithm

Here, n is number of nodes
Topology can be : line, full, rand2D, honeycomb, randhoneycomb, torus
And algorithm can be : pushsum, gossip

Example, 

mix run --no-halt project2.ex 500 torus pushsum

This will run pushsum algorithm for 3D torus topology for a network of 500 nodes

Following table lists down the maximum number of nodes that I was able to run on our machine for all the topologies in both algorithms. Machine Config is attached below 

*Topology:* 
Gossip:
1.	Line : 10,000
2.	Full : 15,000
3.	Rand2D: 50,000
4.	Honey Comb: 100,000
5.	Random Honey Comb: 100,000
6.	3D Torus: 100,000

Push Sum:
1.	Line : 10,000
2.	Full : 10,000
3.	Rand2D: 50,000
4.	Honey Comb: 75,000
5.	Random Honey Comb: 75,000
6.	3D Torus: 75,000

** MACHINE CONFIG :**

** RESULTS :**

* Observations:*
1. Line has slowest convergence when using gossip algorithm. Full has slowest convergence for pushSum when n tends to increase. Line is slowest as number of neighbor nodes is very less, thus information does not spread out faster.

2. Initially full is able to compete with honeycomb (both normal and rand) and torus. But for higher number of nodes, it starts experiencing difficulties in maintaining data of all the nodes at each node and hence gains additional overhead. Thus it becomes slow for larger n when using PushSum.

3. For Gossip Algorithm, Torus seems to be the obvious choice because as n grows, it gives better convergence time than others. For PushSum though, fastest one is Random Honeycomb.

4. For PushSum algo, all the topology behaves nearly similar, but there is a sharp change in curvature when number of nodes becomes 2000.

5. Some topologies with lower max degree of nodes are able to edge out a better performance than some of the topologies with higher max degree nodes. For example, line beats full, rand2D in push sum in some cases.

* Graphs :*

Running Time in ms vs Number of Nodes for GossipAlgorithm in all topologies.
![Running Time in ms vs Number of Nodes for Gossip](https://github.com/gauravUFL/Distributed-Gossip-Algorithm-Simulator/blob/main/Gossip%20Time.png)

Running Time in ms vs Number of Nodes for PushSumAlgorithm in all topologies.
![Running Time in ms vs Number of Nodes for PushSum](https://github.com/gauravUFL/Distributed-Gossip-Algorithm-Simulator/blob/main/PushSum%20Time.png)

Log of Running Time in ms vs Number of Nodes for Gossip Algorithm in all topologies.
![Log of Running Time in ms vs Number of nodes for Gossip](https://github.com/gauravUFL/Distributed-Gossip-Algorithm-Simulator/blob/main/Gossip%20Time%20Log.png)

Log of Running Time in ms vs Number of Nodes for PushSum Algorithm in all topologies.
![Log of Running Time in ms vs Number of Nodes for PushSum](https://github.com/gauravUFL/Distributed-Gossip-Algorithm-Simulator/blob/main/PushSum%20Time%20Log.png)
