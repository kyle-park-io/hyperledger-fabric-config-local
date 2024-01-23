#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -q $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/orderer

ORDERER_NUM=${1}
: ${ORDERER_NUM:=0}

function startOrderer() {
    ORDERER_PORT=$(((($ORDERER_NUM + 7) * 1000) + 50))
    ORDERER_LISTEN_PORT=$(((($ORDERER_NUM + 7) * 1000) + 444))
    FILE_LEDGER_LOC=${TEST_NETWORK_HOME}/production/orderers/orderer${ORDERER_NUM}.example.com
    export CORE_VM_ENDPOINT=
    export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=
    export FABRIC_LOGGING_SPEC="INFO"
    # export FABRIC_LOGGING_SPEC="DEBUG"
    export ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
    export ORDERER_GENERAL_LISTENPORT=${ORDERER_PORT}
    export ORDERER_GENERAL_GENESISMETHOD=file
    export ORDERER_GENERAL_GENESISFILE=${TEST_NETWORK_HOME}/channel-artifacts/genesis.block
    # export ORDERER_GENERAL_BOOTSTRAPMETHOD=file
    # export ORDERER_GENERAL_BOOTSTRAPFILE=${TEST_NETWORK_HOME}/channel-artifacts/genesis.block
    export ORDERER_GENERAL_LOCALMSPID="OrdererMSP"
    export ORDERER_GENERAL_LOCALMSPDIR=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${ORDERER_NUM}.example.com/msp
    export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:${ORDERER_LISTEN_PORT}
    # # enabled TLS
    export ORDERER_GENERAL_TLS_ENABLED=true
    export ORDERER_GENERAL_TLS_PRIVATEKEY=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${ORDERER_NUM}.example.com/tls/server.key
    export ORDERER_GENERAL_TLS_CERTIFICATE=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${ORDERER_NUM}.example.com/tls/server.crt
    export ORDERER_GENERAL_TLS_ROOTCAS=[${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${ORDERER_NUM}.example.com/tls/ca.crt]
    export ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${ORDERER_NUM}.example.com/tls/server.crt
    export ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${ORDERER_NUM}.example.com/tls/server.key
    export ORDERER_GENERAL_CLUSTER_ROOTCAS=[${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${ORDERER_NUM}.example.com/tls/ca.crt]
    export ORDERER_FILELEDGER_LOCATION=${FILE_LEDGER_LOC}
    export ORDERER_CONSENSUS_WALDIR=${FILE_LEDGER_LOC}/etcdraft/wal
    export ORDERER_CONSENSUS_SNAPDIR=${FILE_LEDGER_LOC}/etcdraft/snapshot

    nohup sh -c '${BIN_DIR}/orderer' >${LOG_DIR}/orderer${ORDERER_NUM}.log 2>&1 &
    pid=$!
    echo $pid >pid/orderer${ORDERER_NUM}.pid
}

startOrderer
