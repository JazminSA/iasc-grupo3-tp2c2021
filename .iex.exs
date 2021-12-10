
################################### COMMANDS ###################################

# if length(Node.list()) < 1 do
# end

####### Creating Queues #######
# {pidPSQ, pidPSA} = QueueManager.create(:MessageQueuePS, :pub_sub)
# {pidRRQ, pidRRA} = QueueManager.create(:MessageQueueRR, :pub_sub)

# ManagerNodesAgent.get

# :sys.get_state(pidPSQ)
# :sys.get_state(pidPSA)

####### Creating consumers #######
# Consumer.create(:Consumer1)
# Consumer.create(:Consumer2)
# Consumer.create(:Consumer3)

####### Subscribing consumers #######
# Consumer.subscribe(:Consumer1, :MessageQueuePS, :transactional)
# Consumer.subscribe(:Consumer2, :MessageQueuePS, :not_transactional)
# Consumer.subscribe(:Consumer3, :MessageQueuePS, :not_transactional)

# Consumer.subscribe(:Consumer1, :MessageQueueRR, :transactional)
# Consumer.subscribe(:Consumer2, :MessageQueueRR, :transactional)
# Consumer.subscribe(:Consumer3, :MessageQueueRR, :transactional)

####### Check registrys #######
# Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer1)
# Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer2)

# Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueuePS}})
# Registry.lookup(ConsumersRegistry, {:via, Registry, {QueuesRegistry, :MessageQueueRR}})

####### Producer send messages on demand #######
# Producer.publish(:MessageQueuePS, %{:message => :msg1})
# Producer.publish(:MessageQueueRR, %{:message => :msg1})

####### Producer send messages recurrently #######
# PokemonProducer.Supervisor.start_link([])
# PokemonProducer.publish_to_all()

####### Unsubscribing consumers #######
# Consumer.unsubscribe(:Consumer1, :MessageQueuePS)

:observer.start