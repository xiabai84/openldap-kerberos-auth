#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/libkafka.sh

# Load Kafka environment variables
. /opt/bitnami/scripts/kafka-env.sh

print_welcome_page

sleep 40
KAFKA_SRV_ACCOUNT=kafka/kafka
ZOO_SRV_ACCOUNT=zookeeper/zookeeper.zk-kafka_cluster.local
KAFKA_KEYTAB=/tmp/kafka.service.keytab
ZOO_KEYTAB=/tmp/zookeeper.service.keytab


echo "#### Check Kerberos Ticket from Kafka server side: ls -l /tmp:"
ls -l /tmp
chmod a+r $KAFKA_KEYTAB
chmod a+r $ZOO_KEYTAB

echo "##### kinit grab a ticket for principal $KAFKA_SRV_ACCOUNT:"
kinit -k -t $KAFKA_KEYTAB $KAFKA_SRV_ACCOUNT

echo "##### kinit grab a ticket for principal $ZOO_SRV_ACCOUNT:"
kinit -k -t $ZOO_KEYTAB $ZOO_SRV_ACCOUNT

klist

if [[ "$*" = *"/opt/bitnami/scripts/kafka/run.sh"* || "$*" = *"/run.sh"* ]]; then
    info "** Starting Kafka setup **"
    /opt/bitnami/scripts/kafka/setup.sh
    info "** Kafka setup finished! **"
fi

echo ""
exec "$@"
