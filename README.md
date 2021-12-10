# MessageQueueSystem

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `message_queue_system` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:message_queue_system, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/message_queue_system](https://hexdocs.pm/message_queue_system).


# COMMANDS 
## Up first node #######
iex --name a@127.0.0.1 -S mix
# ManagerNodesAgent.get
iex --name b@127.0.0.1 -S mix

## Creating Queues #######
{pidPSQ, pidPSA} = QueueManager.create(:MessageQueuePS, :pub_sub) 
{pidRRQ, pidRRA} = QueueManager.create(:MessageQueueRR, :round_robin)

## Show synched registries and agents
QueuesRegistry.list
MessageQueueAgent.get_queue_state(:MessageQueuePS)
MessageQueueAgent.get_queue_state(:MessageQueueRR)

## Show active node for queues
ManagerNodesAgent.get

## Creating consumers #######
Consumer.create(:Consumer1)
Consumer.create(:Consumer2)
Consumer.create(:Consumer3)

## Subscribing consumers #######
Consumer.subscribe(:Consumer1, :MessageQueuePS, :transactional)
Consumer.subscribe(:Consumer2, :MessageQueuePS, :not_transactional)
Consumer.subscribe(:Consumer3, :MessageQueuePS, :not_transactional)

Consumer.subscribe(:Consumer1, :MessageQueueRR, :not_transactional)
Consumer.subscribe(:Consumer2, :MessageQueueRR, :not_transactional)
Consumer.subscribe(:Consumer3, :MessageQueueRR, :transactional)

## Check synched registrys and states #######
Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer1)
Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer2)
Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer3)

Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueuePS}})
Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueueRR}})

## Producer send messages on demand #######
Producer.publish(:MessageQueueRR, %{:message => :msg1})
ManagerNodesAgent.get
PokemonProducer.publish_msg_to(:MessageQueuePS, "pikachu")
PokemonProducer.publish_msg_to(:MessageQueueRR, "charmander")

:sys.get_state({:via, Registry, {QueuesRegistry, :MessageQueuePS}})
MessageQueueAgent.get_queue_state(:MessageQueuePS)
MessageQueueAgent.get_queue_state(:MessageQueueRR)

## Producer send messages recurrently to one queue #######
PokemonProducer.normal_mode

PokemonProducer.publish_to :MessageQueueRR
PokemonProducer.stop_publish_to :MessageQueueRR

PokemonProducer.publish_to :MessageQueuePS
PokemonProducer.stop_publish_to :MessageQueuePS

## Producer send messages recurrently to all queues #######
PokemonProducer.publish_to_all()

## Unsubscribing consumers #######
[Node X] Consumer.unsubscribe(:Consumer1, :MessageQueueRR)
[Node X] Consumer.unsubscribe(:Consumer2, :MessageQueueRR)
[Node X] Consumer.unsubscribe(:Consumer3, :MessageQueueRR)
Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueueRR}})

# Up observer 
:observer.start

## Other usefull commands ###########
export ERL_AFLAGS="-kernel shell_history enabled"
:sys.get_state(pid)

## TESTS PRODUCER ########## 
{pidPSQ, pidPSA} = QueueManager.create(:MessageQueuePS, :pub_sub)
Consumer.create(:Consumer1)
Consumer.subscribe(:Consumer1, :MessageQueuePS, :not_transactional)

## Colas a las que el productor actualmente está produciendo
PokemonProducer.queues

## Producir un único mensaje a una cola especifíca. 
El segundo parámetro es el número de pokemon a enviar (también se puede pasar el nombre)
PokemonProducer.publish_msg_to(:MessageQueuePS, 25)
PokemonProducer.publish_msg_to(:MessageQueuePS, "pikachu")

## Producir (permanentemente) a una cola especifíca
PokemonProducer.publish_to :MessageQueuePS

## Dejar de producir a una cola especifíca
PokemonProducer.stop_publish_to :MessageQueuePS

## Producir (permanentemente) a todas las colas registradas
PokemonProducer.publish_to_all

## Dejar de producir a todas las colas registradas
PokemonProducer.stop_publish_to_all

## Cambiar velocidad de producción (mientras se está produciendo)
PokemonProducer.slow_mode # -> Envia un mensaje cada 10 seg
PokemonProducer.normal_mode # -> Envia un mensaje cada 5 seg
PokemonProducer.fast_mode # -> Envia un mensaje cada 1 seg
PokemonProducer.custom_mode(ms_value) # -> Envia un mensaje cada ms_value ms






