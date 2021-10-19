# iasc-grupo3-tp2c2021
Trabajo Práctico Cuatrimestral
IASC - Implementación de Arquitecturas de Software Concurrente
UTN BA

## 2. El problema

Una cola de mensajes es un componente arquitectural que permite una comunicación asincrónica y confiable entre dos nodos: un productor que publica mensajes, y un consumidor que los lee e interpreta. Las colas viven dentro de un software llamado gestor de colas de mensajes o simplemente, sistema de mensajería, que permite crear, eliminar y mantener en funcionamiento una o más colas. 

El objeto de este trabajo práctico es diseñar y construir un gestor de colas de mensajes, aplicando los conceptos y tecnologías vistos en la materia. 

## 3. Requerimientos

###3.1 Velocidades de producción y consumo diferente

La cola debe permitir que la producción y el consumo de mensajes ocurra a velocidades diferentes:   
el productor podría generar mensajes más lentamente de lo que el consumidor los procesa, con lo que el consumidor debería quedar en espera no-activa hasta que haya un mensaje nuevo, o bien...
...el productor podría generar mensajes más rápidamente de lo que el consumidor los procesa, con lo que la cola debería almacenarlos temporalmente hasta que sean todos consumidos, actuando como buffer. 

###3.2 Modos de trabajo

En una cola podrá haber múltiples productores que produzcan mensajes, sin afectar su funcionamiento. De igual forma, podrá haber múltiples consumidores; en este caso la cola debe trabajar en una de dos modalidades, configurables al crear la cola: 

- cola de trabajo: el mensaje será entregado únicamente a uno de los consumidores disponibles, elegido de forma round-robin

- publicar-suscribir (PubSub): el mensaje será entregado a todos los consumidores disponibles.

###3.3 Confiabilidad

Los mensajes no deben eliminarse de la cola si no han sido apropiadamente consumidos, y no deben entregarse más de una vez a un cliente: 
en la modalidad cola de trabajo, los mensajes se eliminarán cuando hayan sido procesado por exactamente un consumidor, y no deberá entregarse a ningún otro cliente. 
en la modalidad publicar-suscribir, los mensajes sólo se eliminarán cuando hayan sido procesados por todos los consumidores, y no se entregarán más de una vez a cada uno de ellos. 
Dado que se contarán sólo los consumidores existentes al momento de recibir el mensaje, si un consumidor se agrega luego de recibido el mensaje, no deberá consumirlo. 

Los mensajes no deben ser almacenados una vez consumidos, para minimizar el consumo de memoria.

###3.4 [Opcional] Transaccionalidad 

Opcionalmente, los clientes podrán consumir los mensajes en dos modalidades: no transaccional y transaccional. 
####3.4.1 Consumo no transaccional
En este caso, un mensaje se considera consumido por un cliente en cuanto es entregado al mismo. 

####3.4.2 Consumo transaccional
En este caso, un mensaje se considera consumido por un cliente recién cuando el cliente lo confirma explícitamente (ACK). 
En esta modalidad, si un mensaje es entregado a un consumidor, pero el mismo no emite un ACK en un tiempo razonable (timeout), el sistema deberá considerar que el consumo falló y deberá: 
- entregarlo a otro consumidor en la modalidad cola de trabajo,
- reencolado en la cola hasta que el consumidor vuelva a intentar consumirlo en la modalidad publicar-suscribir.

###3.5 Formato de los mensajes

Los mensajes no necesitan cumplir un formato particular, y queda a criterio del equipo: podrá ser por ejemplo binario, texto plano, JSON, etc. 

Los mensajes podrían contener metadatos que ayuden a identificarlos, tratarlos, trazarlos y debuggearlos, a criterio del equipo, como quien lo produjo, un identificador único, la fecha y hora en que el sistema de mensajería recibió el mensaje, etc. 

###3.6 Almacenamiento en memoria

La cola debe poder almacenar los mensajes íntegramente en memoria, sin recurrir a bases de datos externas, por lo que la cantidad de mensajes de una cola está sólo limitada por la cantidad de memoria virtual disponible en el sistema. De todas formas, es deseable que se pueda configurar un límite a la cantidad de mensajes y/o un tamaño máximo. 

###3.7 Distribución

Para poder aumentar la cantidad de mensajes que el sistema puede manejar, se debe poder soportar un modo distribuido en el que es posible adicionar al mismo nodos que aumenten la cantidad de memoria disponible. 

Es importante que esta distribución posibilite escalar horizontalmente, es decir, que sea posible incrementar la capacidad del sistema mediante la adición de nodos, en lugar de aumentando la capacidad de los mismos. 

###3.8 Tolerancia a fallos
Además, en el modo distribuido, las colas de mensajes deben ser tolerantes a fallos: si un nodo se cae, sus mensajes deben poder ser restaurados desde otro u otros de forma transparente para los clientes del sistema de mensajería. 

###3.9 [Opcional] API Administrativa

Opcionalmente, el gestor de colas de mensajes debe contar con un API HTTP Rest para crear y eliminar colas, así como poder obtener información estadística sobre cada una. 

###3.10 [Deseable] Comunicación eficiente a través de una red pública

No se tendrán en cuenta cuestiones de seguridad; se asumirá que todos los clientes y servidores están dentro de una red segura. 

De igual forma, no se impondrán limitaciones sobre el protocolo de comunicación entre los clientes de la cola (ya sean consumidores o productores) y la cola en sí; por ejemplo, una opción válida podría ser el uso de HTTP. 

Sin embargo, HTTP no es la mejor opción, dado que:
- al ser imponer una arquitectura cliente servidor, los consumidores deben tener una IP accesible desde el gestor y estática
- al ser un protocolo no orientado a la conexión, no es eficiente crear una conexión por cada mensaje entregado
- al ser un protocolo textual, no posibilidad una forma compacta de representación de los mensajes

Por tanto, es deseable que se emplee en su lugar un protocolo binario, orientado a la conexión y bidireccional, como TCP, o un protocolo binario, liviano, no orientado a la conexión, como UDP. 

###3.11 [Opcional] Despliegue mediante contenedores

Es deseable que el despliegue se haga mediante contenedores Docker. 


##4 Las tecnologías

Se podrá utilizar cualquier tecnología que aplique alguno de los siguientes conceptos vistos en la cursada:
- Corrutinas
- Continuaciones explícitas (CPS)
- Promises
- Paso de mensajes basado en actores

Obviamente, lo más simple es basarse en Ruby, Python, Node.js o Elixir/OTP, que son las tecnologías principales que vimos en la materia. 

Otras opciones son tecnologías basadas en Scala/Akka, Go, Clojure y Rust, pero ahí les podremos dar menos soporte. También pueden implementarlo en cualquier otra tecnología, que no sea ninguna de las mencionadas, aunque recomendamos que sea una que conozca gran parte de los miembros del grupo.

