#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -s $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

function startCA() {
    export FABRIC_CA_HOME=${TEST_NETWORK_HOME}/organizations/fabric-ca-server
    export FABRIC_CA_SERVER_CA_NAME="ca"
    export FABRIC_CA_SERVER_TLS_ENABLED=true
    export FABRIC_CA_SERVER_PORT="7054"
    export FABRIC_CA_SERVER_CSR_CN="ca"
    export FABRIC_CA_SERVER_CSR_HOSTS="ca,localhost"
    export FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS="0.0.0.0:7443"

    nohup sh -c '${BIN_DIR}/fabric-ca-server start -b admin:adminpw -d' >${LOG_DIR}/fabric-ca-server.log 2>&1 &
    pid=$!
    echo $pid >pid/ca.pid
}

startCA