# #Commands
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

# Consumer.subscribe(pidConsumer, :MessageQueueRR, :not_transactional)
# Consumer.subscribe(pidConsumer2, :MessageQueueRR, :not_transactional)
# Consumer.subscribe(pidConsumer3, :MessageQueueRR, :not_transactional)

# # ver consumers de una cola
# #Registry.lookup(ConsumersRegistry, :MessageQueuePS)
# #Registry.lookup(ConsumersRegistry, :MessageQueueRR)

# #Vincular producer a una cola / producer enviar mensaje
# # Producer.publish(:MessageQueuePS, %{:message => "first_message"})
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

:observer.start
