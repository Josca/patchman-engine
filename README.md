# Kafka SSL_SASL docker-compose example
~~~bash
docker-compose up --build -d
docker-compose logs -f kafka
~~~

- Broker is not started, getting errors:
~~~
...
kafka        | [main] INFO org.apache.zookeeper.common.X509Util - Setting -D jdk.tls.rejectClientInitiatedRenegotiation=true to disable client-initiated TLS renegotiation
kafka        | [main] INFO org.apache.zookeeper.ClientCnxnSocket - jute.maxbuffer value is 4194304 Bytes
kafka        | [main] INFO org.apache.zookeeper.ClientCnxn - zookeeper.request.timeout value is 0. feature enabled=
kafka        | [main-SendThread(zookeeper:2181)] INFO org.apache.zookeeper.ClientCnxn - Opening socket connection to server zookeeper/172.18.0.2:2181
kafka        | WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
kafka        | [main-SendThread(zookeeper:2181)] INFO org.apache.zookeeper.ClientCnxn - Socket connection established, initiating session, client: /172.18.0.3:49688, server: zookeeper/172.18.0.2:2181
kafka        | Error while executing topic command : Replication factor: 1 larger than available brokers: 0.
kafka        | [2021-06-07 11:56:20,702] ERROR org.apache.kafka.common.errors.InvalidReplicationFactorException: Replication factor: 1 larger than available brokers: 0.
kafka        |  (kafka.admin.TopicCommand$)
kafka        | [main-SendThread(zookeeper:2181)] INFO org.apache.zookeeper.ClientCnxn - Session establishment complete on server zookeeper/172.18.0.2:2181, sessionid = 0x1000c51e2ec0002, negotiated timeout = 40000
kafka        | Unable to create topic platform.inventory.events
kafka        | WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
kafka        | Error while executing topic command : Replication factor: 1 larger than available brokers: 0.
kafka        | [2021-06-07 11:56:22,855] ERROR org.apache.kafka.common.errors.InvalidReplicationFactorException: Replication factor: 1 larger than available brokers: 0.
kafka        |  (kafka.admin.TopicCommand$)
kafka        | Unable to create topic platform.inventory.events
~~~
