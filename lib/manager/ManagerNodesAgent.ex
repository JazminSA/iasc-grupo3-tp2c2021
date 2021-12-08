defmodule ManagerNodesAgent do
  use Agent

  def start_link(_initial_state) do
    state = case length(Node.list()) do
      0 -> %{nodes: %{}, queues: %{}}
      _ -> :erpc.call(Enum.random(Node.list()), ManagerNodesAgent, :get, [])
    end
    Agent.start_link(fn -> state end, name: __MODULE__)
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
    lazier_node
  end

  def assign_queue_to_node(queue_id, node_id) do
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

  def assign_queues_to_node(queues, node_id) do
    Enum.each(queues, fn q -> assign_queue_to_node(q, node_id) end)
  end

  def get_queues_in_node() do
    get_queues_in_node(Node.self())
  end

  def get_queues_in_node(node) do
    state = ManagerNodesAgent.get()
    queues = Enum.filter(Map.get(state, :queues), fn {_, node_id} -> node_id == node end)
    Enum.map(queues, fn {queue, _node} -> queue end)
  end

  def get_lazier_node() do
    state = ManagerNodesAgent.get()
    min_node_by_queues_count(Map.get(state, :nodes))
  end

  def get_node_for_queue(queue_id) do
    state = ManagerNodesAgent.get()
    get_in(state, [:queues, queue_id])
  end

  def transfer_queues(origin, destination) do
    queues = get_queues_in_node(origin)
    assign_queues_to_node(queues, destination)
  end

  defp min_node_by_queues_count(%{}) do
    Node.self()
  end

  defp min_node_by_queues_count(nodes)  do
    Enum.min_by(nodes, fn {_k, count} -> count end)
  end
end
