#Commands

if length(Node.list()) < 1 do

# pidPS = QueueManager.create_queue(:MessageQueuePS, :pub_sub)
# pidRR = QueueManager.create_queue(:MessageQueueRR, :round_robin)

#creo consumers
Consumer.create(:Consumer1)

#subscribo consumers
Consumer.subscribe(:Consumer1, :MessageQueuePS, :transactional)
Consumer.subscribe(:Consumer1, :MessageQueuePS2, :transactional)
  
# ver consumers de una cola
  # Registry.lookup(ConsumersSubscriptionsRegistry, :Consumer1)
  # Registry.lookup(ConsumersRegistry, :MessageQueuePS)
  # Registry.lookup(ConsumersRegistry, :MessageQueuePS2)

# unsubscribe consumers
Consumer.unsubscribe(:Consumer1, :MessageQueuePS)

#Vincular producer a una cola / producer enviar mensaje
# Producer.publish(:MessageQueuePS, %{:message => "first_message"})
PokemonProducer.Supervisor.start_link([])
# PokemonProducer.publish()

end

:observer.start
