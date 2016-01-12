## Summary

deploying Dockerized services on Mesos frameworks. A few services including Kafka, Zookeeper and
RabbitMQ have been successfully deployed on such platform.

Using Marathon and Chronos frameworks, application/service deployment to various environments
become much simpler comparing with CF based platform. Both containerized and regular applications
can be seamlessly deployed on Mesos abstraction platforms without complex configuration or run-time
environment modification. Leveraging service discovery automation and load balancing functions,
multiple service instances can be easily deployed to the platform with full redundancy and without
manual intervention.


## Archiitecture


![alt tag](https://github.com/alfredcs/Docker-Marathon/mesos-platform.png)


## Considerations and Benefits:

Stability: The approach should be simple and repeatable. The platform should be stable and
supportable by engineers from GE.
Fault Tolerance: The platform should have no single point of failure on service. All controller
services are clustered without single point of failure. Failed services will be restarted automatically.
Services and their dependencies and isolated by containers.
Security: All customer facing API are secured with SSL and password protection.
Agility: Service can be dynamically deployed and migrated to another host. Seamless upgrades are norm.
Capacity Management: Addition nodes can be dynamically added or removed from the mesosslave farm.
Infrastructure Agnostic: The reference architect can be deployed on AWS, Bare Metals and Virtual servers.


Please refer to the "Container Platform With Mesos on Box Notes.pdf" for further details.
