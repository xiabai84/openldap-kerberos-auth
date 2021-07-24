#!/bin/bash

sleep 30
# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/libzookeeper.sh

# Load ZooKeeper environment variables
. /opt/bitnami/scripts/zookeeper-env.sh

print_welcome_page

ZOO_SRV_ACCOUNT=zookeeper/zookeeper.zk-kafka_cluster.local
ZOO_KEYTAB=/tmp/zookeeper.service.keytab
echo "##### kinit grab a ticket for principal $ZOO_SRV_ACCOUNT:"
kinit -k -t $ZOO_KEYTAB $ZOO_SRV_ACCOUNT

klist

if [[ "$*" = *"/opt/bitnami/scripts/zookeeper/run.sh"* || "$*" = *"/run.sh"* ]]; then
    info "** Starting ZooKeeper setup **"
    /opt/bitnami/scripts/zookeeper/setup.sh
    info "** ZooKeeper setup finished! **"
fi

echo ""
exec "$@"
