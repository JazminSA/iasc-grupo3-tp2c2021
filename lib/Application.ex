defmodule MQApplication do
    use Application

    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      topologies = [
        myapp: [
          strategy: Cluster.Strategy.Epmd,
          config: [hosts: [:"a@127.0.0.1", :"b@127.0.0.1"]], #cantidad de nodos
        ]
      ]
      children = [
        {Cluster.Supervisor, [topologies, [name: MyApp.ClusterSupervisor]]},
        QueueManagerSupervisor,
        ProducerSupervisor,
        %{id: ConsumerDynamicSupervisor, start: {ConsumerDynamicSupervisor, :start_link, [[]]} },
        %{id: MessageQueueDynamicSupervisor, start: {MessageQueueDynamicSupervisor, :start_link, [[]]} },
        ConsumersRegistrySupervisor
      ]

      opts = [strategy: :one_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  #iex --name a@127.0.0.1 -S mix
  #iex --name b@127.0.0.1 -S mix
  #haciendo el start de esta forma, los nodos se conectan automaticamente y levanta una app con todos sus childs en cada nodo, es decir, replica...
  #usando Cluster.Strategy.Epmd
