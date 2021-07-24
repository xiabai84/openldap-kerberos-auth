#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libzookeeper.sh
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/liblog.sh

# Load ZooKeeper environment variables
. /opt/bitnami/scripts/zookeeper-env.sh
export SERVER_JVMFLAGS="-Djava.security.auth.login.config=/opt/bitnami/zookeeper/conf/zookeeper_jaas.conf -Dsun.security.krb5.debug=true"
export KAFKA_OPTS="-Dsun.security.krb5.debug=true -Djava.security.auth.login.config=/opt/bitnami/zookeeper/conf/zookeeper_jaas.conf"
#export KAFKA_OPTS="-Dsun.security.krb5.debug=true -Djava.security.krb5.conf=/etc/krb5.conf -Djava.security.auth.login.config=/opt/bitnami/zookeeper/conf/zookeeper_jaas.conf"

START_COMMAND=("${ZOO_BASE_DIR}/bin/zkServer.sh ${ZOO_CONF_FILE}")
#START_COMMAND=("${ZOO_BASE_DIR}/bin/zkServer.sh" "start-foreground" "$@")


echo "#### ZooKeeper Starting: $START_COMMAND"

echo

info "** Starting ZooKeeper **"
if am_i_root; then
#    exec gosu "$ZOO_DAEMON_USER" "${START_COMMAND}"
    echo "Exec: as root"
    ${ZOO_BASE_DIR}/bin/zkServer.sh --config ${ZOO_CONF_DIR} start-foreground
#    exec gosu "$ZOO_DAEMON_USER" "${START_COMMAND[@]}"
else
  echo "Exec: without root"
  ${ZOO_BASE_DIR}/bin/zkServer.sh --config ${ZOO_CONF_DIR} start-foreground
#  exec "${START_COMMAND}"
#    exec "${START_COMMAND[@]}"
fi
