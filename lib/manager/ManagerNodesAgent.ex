defmodule ManagerNodesAgent do
  use Agent

  def start_link(_initial_state) do
    initial = %{nodes: %{}, queues: %{}}
    Agent.start_link(fn -> initial end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def update(new_state) do
    Agent.update(__MODULE__, fn _ -> new_state end)
  end

  def create_node(node_id) do
    state = ManagerNodesAgent.get()
    new_state = put_in(state, [:nodes, node_id], 0)
    ManagerNodesAgent.update(new_state)
  end

  def assign_queue_to_lazier_node(queue_id) do
    lazier_node = get_lazier_node() || Node.self()
    assign_queue_to_node(queue_id, lazier_node)
  end

  def assign_queue_to_node(queue_id, node_id) do
    IO.puts("assign")
    state = ManagerNodesAgent.get()
    # Update Nodes
    previous_count = case state do
      %{nodes: %{node_id: count}} -> count
      _ -> 0
    end
    new_state = put_in(state, [:nodes, node_id], previous_count + 1)

    # Update queues
    ManagerNodesAgent.update(put_in(new_state, [:queues, queue_id], node_id))
  end

  def get_lazier_node() do
    state = ManagerNodesAgent.get()
    min_node_by_queues_count(Map.get(state, :nodes))
  end

  def get_node_for_queue(queue_id) do
    state = ManagerNodesAgent.get()
    get_in(state, [:queues, queue_id])
  end

  defp min_node_by_queues_count(%{}) do
    Node.self()
  end

  defp min_node_by_queues_count(nodes)  do
    Enum.min_by(nodes, fn {_k, count} -> count end)
  end
end
