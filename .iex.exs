##Commands
# if length(Node.list()) < 1 do
#   pidPS = QueueManager.create(:MessageQueuePS, :pub_sub)
#   pidRR = QueueManager.create(:MessageQueueRR, :round_robin)
# end

## creo consumers
# {:ok, pidConsumer} = Consumer.create()
# {:ok, pidConsumer2} = Consumer.create()
# {:ok, pidConsumer3} = Consumer.create()
# {:ok, pidConsumer4} = Consumer.create()

## subscribo consumers
# Consumer.subscribe(pidConsumer, :MessageQueuePS, :transactional)
# Consumer.subscribe(pidConsumer2, :MessageQueuePS, :not_transactional)
# Consumer.subscribe(pidConsumer3, :MessageQueuePS, :not_transactional)

# Consumer.subscribe(pidConsumer2, :MessageQueueRR, :not_transactional)
# Consumer.subscribe(pidConsumer3, :MessageQueueRR, :not_transactional)
# Consumer.subscribe(pidConsumer4, :MessageQueueRR, :not_transactional)

# Consumer.unsubscribe(pidConsumer3, :MessageQueuePS)

## ver consumers de una cola
# Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueuePS}})
# Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueueRR}})

## Vincular producer a una cola / producer enviar mensaje
# Producer.publish(:MessageQueuePS, %{:message => "msg1"})
# Producer.publish(:MessageQueueRR, %{:message => "msg1"})

# PokemonProducer.Supervisor.start_link([])
# PokemonProducer.publish_to_all()



## named consumers
# pidPS = QueueManager.create(:MessageQueuePS, :pub_sub)
# Consumer.create(:Consumer1)
# Consumer.create(:Consumer2)
# Consumer.subscribe(:Consumer1, :MessageQueuePS, :transactional)
# Consumer.subscribe(:Consumer2, :MessageQueuePS, :not_transactional)
# Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer1)
# Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer2)

# Producer.publish(:MessageQueuePS, %{:message => :msg1})

# Consumer.unsubscribe(:Consumer1, :MessageQueuePS)


# :observer.start
