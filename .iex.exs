
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

# :observer.start



########## TESTS PRODUCER ########## 
# {pidPSQ, pidPSA} = QueueManager.create(:MessageQueuePS, :pub_sub)
# Consumer.create(:Consumer1)
# Consumer.subscribe(:Consumer1, :MessageQueuePS, :not_transactional)

## Colas a las que el productor actualmente está produciendo
# PokemonProducer.queues

## Producir un único mensaje a una cola especifíca. El segundo parámetro
# es el número de pokemon a enviar (también se puede pasar el nombre)
# PokemonProducer.publish_msg_to(:MessageQueuePS, 25)
# PokemonProducer.publish_msg_to(:MessageQueuePS, "pikachu")

## Producir (permanentemente) a una cola especifíca
# PokemonProducer.publish_to :MessageQueuePS

## Dejar de producir a una cola especifíca
# PokemonProducer.stop_publish_to :MessageQueuePS

## Producir (permanentemente) a todas las colas registradas
# PokemonProducer.publish_to_all

## Dejar de producir a todas las colas registradas
# PokemonProducer.stop_publish_to_all

## Cambiar velocidad de producción (mientras se está produciendo)
# PokemonProducer.slow_mode # -> Envia un mensaje cada 10 seg
# PokemonProducer.normal_mode # -> Envia un mensaje cada 5 seg
# PokemonProducer.fast_mode # -> Envia un mensaje cada 1 seg
# PokemonProducer.custom_mode(ms_value) # -> Envia un mensaje cada ms_value ms




