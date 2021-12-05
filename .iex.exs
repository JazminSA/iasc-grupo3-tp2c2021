#Commands

# {:ok, pidRR} =  MessageQueueDynamicSupervisor.start_child(:MessageQueueRR, :round_robin, [])
# {:ok, pidPS} =  MessageQueueDynamicSupervisor.start_child(:MessageQueuePS, :pub_sub, [])
pidPS = QueueManager.create_queue(:MessageQueuePS, :pub_sub)
pidRR = QueueManager.create_queue(:MessageQueueRR, :round_robin)

#creo consumers
{:ok, pidConsumer} = ConsumerDynamicSupervisor.start_child([])
{:ok, pidConsumer2} = ConsumerDynamicSupervisor.start_child([])
{:ok, pidConsumer3} = ConsumerDynamicSupervisor.start_child([])
{:ok, pidConsumer4} = ConsumerDynamicSupervisor.start_child([])

#subscribo consumers
Consumer.subscribe(pidConsumer, :MessageQueuePS, :transactional)
Consumer.subscribe(pidConsumer2, :MessageQueuePS, :not_transactional)
Consumer.subscribe(pidConsumer3, :MessageQueuePS, :not_transactional)

Consumer.subscribe(pidConsumer3, :MessageQueueRR, :not_transactional)

# ver consumers de una cola
Registry.lookup(ConsumersRegistry, :MessageQueuePS)
Registry.lookup(ConsumersRegistry, :MessageQueueRR)


#Vincular producer a una cola / producer enviar mensaje
#Producer.publish(:MessageQueuePS, %{:message => "first_message"})

:observer.start