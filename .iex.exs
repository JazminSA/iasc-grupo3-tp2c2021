#Commands
<<<<<<< Updated upstream

if length(Node.list()) < 1 do

  # pidPS = QueueManager.create(:MessageQueuePS, :pub_sub)
  # pidPS2 = QueueManager.create(:MessageQueuePS2, :pub_sub)
  # pidRR = QueueManager.create(:MessageQueueRR, :round_robin)

  #creo consumers
  # Consumer.create(:Consumer1)

  # #subscribo consumers
  # Consumer.subscribe(:Consumer1, :MessageQueuePS, :transactional)
  # Consumer.subscribe(:Consumer1, :MessageQueuePS2, :transactional)
    
  # # ver consumers de una cola
  # # Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer1)
  # # Registry.lookup(ConsumersRegistry, :MessageQueuePS)
  # # Registry.lookup(ConsumersRegistry, :MessageQueuePS2)

  # # unsubscribe consumers
  # Consumer.unsubscribe(:Consumer1, :MessageQueuePS)

  # #Vincular producer a una cola / producer enviar mensaje
  # # Producer.publish(:MessageQueuePS, %{:message => "message1"})
  # PokemonProducer.Supervisor.start_link([])
  # # PokemonProducer.publish_to_all()

end
=======
# if length(Node.list()) < 1 do
#   # {:ok, pidRR} =  MessageQueueDynamicSupervisor.start_child(:MessageQueueRR, :round_robin, [])
#   # {:ok, pidPS} =  MessageQueueDynamicSupervisor.start_child(:MessageQueuePS, :pub_sub, [])
#   # pidPS = QueueManager.create(:MessageQueuePS, :pub_sub)
#   #pidRR = QueueManager.create(:MessageQueueRR, :round_robin)
# end

#creo consumers
# {:ok, pidConsumer} = Consumer.create()
# {:ok, pidConsumer2} = Consumer.create()
# {:ok, pidConsumer3} = Consumer.create()
#{:ok, pidConsumer3} = ConsumerDynamicSupervisor.start_child([])
#{:ok, pidConsumer4} = ConsumerDynamicSupervisor.start_child([])

#subscribo consumers
#Consumer.subscribe(pidConsumer, :MessageQueuePS, :transactional)
#Consumer.subscribe(pidConsumer2, :MessageQueuePS, :not_transactional)
##Consumer.subscribe(pidConsumer3, :MessageQueuePS, :not_transactional)

# Consumer.subscribe(pidConsumer, :MessageQueuePS, :not_transactional)
# Consumer.subscribe(pidConsumer2, :MessageQueuePS, :not_transactional)
# Consumer.subscribe(pidConsumer3, :MessageQueuePS, :not_transactional)

# ver consumers de una cola
#Registry.lookup(ConsumersRegistry, :MessageQueuePS)
#Registry.lookup(ConsumersRegistry, :MessageQueueRR)

#Vincular producer a una cola / producer enviar mensaje
# Producer.publish(:MessageQueuePS, %{:message => "first_message"})
# PokemonProducer.Supervisor.start_link([])
# PokemonProducer.publish()
>>>>>>> Stashed changes

:observer.start
