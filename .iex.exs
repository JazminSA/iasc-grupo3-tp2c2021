#Commands

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

:observer.start
