FROM ubuntu:15.10

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 514A2AD631A57A16DD0047EC749D6EEC0353B12C

ENV CASSANDRA_VERSION 3.2
ENV CASSANDRA_CONFIG /etc/cassandra

RUN     echo 'deb http://www.apache.org/dist/cassandra/debian 32x main' >> /etc/apt/sources.list.d/cassandra.list \
        && apt-get update \
        && apt-get install -y cassandra="$CASSANDRA_VERSION" \
        &&  rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /var/lib/cassandra
VOLUME /var/log/cassandra

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX monitoring port
# 8888: OpsCenter website
# 9042: CQL
# 9160: thrift service
# 61620: OpsCenter monitoring port.
# 61621: OpsCenter agentport.
EXPOSE 7000 7001 7199 8888 9042 9160 61620 61621
CMD ["cassandra", "-f"]

