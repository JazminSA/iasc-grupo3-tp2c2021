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

#Commands
# if length(Node.list()) < 1 do
#   # {:ok, pidRR} =  MessageQueueDynamicSupervisor.start_child(:MessageQueueRR, :round_robin, [])
#   # {:ok, pidPS} =  MessageQueueDynamicSupervisor.start_child(:MessageQueuePS, :pub_sub, [])
#   pidPS = QueueManager.create(:MessageQueuePS, :pub_sub)
#   #pidRR = QueueManager.create_queue(:MessageQueueRR, :round_robin)
# end

# #creo consumers
# {:ok, pidConsumer} = Consumer.create()
# {:ok, pidConsumer2} = Consumer.create()
# {:ok, pidConsumer3} = Consumer.create()

# #{:ok, pidConsumer3} = ConsumerDynamicSupervisor.start_child([])
# #{:ok, pidConsumer4} = ConsumerDynamicSupervisor.start_child([])

# #subscribo consumers
# #Consumer.subscribe(pidConsumer, :MessageQueuePS, :transactional)
# #Consumer.subscribe(pidConsumer2, :MessageQueuePS, :not_transactional)
# ##Consumer.subscribe(pidConsumer3, :MessageQueuePS, :not_transactional)

# # Consumer.subscribe(pidConsumer, :MessageQueueRR, :not_transactional)
# # Consumer.subscribe(pidConsumer2, :MessageQueueRR, :not_transactional)
# # Consumer.subscribe(pidConsumer3, :MessageQueueRR, :not_transactional)
# # Consumer.subscribe(pidConsumer, :MessageQueuePS, :not_transactional)
# # Consumer.subscribe(pidConsumer2, :MessageQueuePS, :not_transactional)
# # Consumer.subscribe(pidConsumer3, :MessageQueuePS, :not_transactional)
# # ver consumers de una cola
# #Registry.lookup(ConsumersRegistry, :MessageQueuePS)
# #Registry.lookup(ConsumersRegistry, :MessageQueueRR)

# #Vincular producer a una cola / producer enviar mensaje
# #Producer.publish(:MessageQueuePS, %{:message => "first_message"})
# PokemonProducer.Supervisor.start_link([])
# # PokemonProducer.publish()

# :observer.start

# Agent.get(pid("0.405.0"), fn state -> inspect state end)
# {pidPSQ, pidPSA} = pidPS
# :sys.get_state(pidPSA)


#####################

# {pidPSQ2, pidPSA2} = Node.s
# {pidRRQ, pidRRA} = QueueManager.create(:MessageQueueRR, :round_robin)
# Consumer.create(:Consumer1)
# Consumer.create(:Consumer2)
# Consumer.subscribe(:Consumer1, :MessageQueuePS3, :transactional)
# Consumer.subscribe(:Consumer2, :MessageQueuePS, :not_transactional)
# Consumer.subscribe(:Consumer3, :MessageQueuePS, :not_transactional)

# Consumer.subscribe(:Consumer1, :MessageQueueRR, :transactional)
# Consumer.subscribe(:Consumer2, :MessageQueueRR, :transactional)
# Consumer.subscribe(:Consumer3, :MessageQueueRR, :transactional)


# Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer1)
# Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer2)

# Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueuePS}})

# Producer.publish(:MessageQueuePS, %{:message => :msg1})
# Producer.publish(:MessageQueueRR, %{:message => :msg1})

# Consumer.unsubscribe(:Consumer1, :MessageQueuePS)