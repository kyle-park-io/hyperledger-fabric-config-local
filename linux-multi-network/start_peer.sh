#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -s $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/peer

PEER_NUM=${1}
: ${PEER_NUM:=0}

function startPeer() {
    PEER_PORT=$(((($PEER_NUM + 7) * 1000) + 51))
    PEER_LISTEN_PORT=$(((($PEER_NUM + 7) * 1000) + 445))
    PEER_CHAINCODE_PORT=$(((($PEER_NUM + 7) * 1000) + 52))
    export FABRIC_LOGGING_SPEC="INFO"
    # export FABRIC_LOGGING_SPEC="DEBUG"
    export CORE_VM_ENDPOINT=""
    export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=""
    # # enabled TLS
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_PROFILE_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/msp
    export CORE_PEER_TLS_CERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/tls/server.crt
    export CORE_PEER_TLS_KEY_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/tls/server.key
    export CORE_PEER_TLS_ROOTCERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/tls/ca.crt
    export CORE_PEER_ID=peer${PEER_NUM}.org1.example.com
    # tls
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.org1.example.com:${PEER_PORT}
    export CORE_PEER_LISTENADDRESS="0.0.0.0":${PEER_PORT}
    export CORE_PEER_CHAINCODEADDRESS=peer${PEER_NUM}.org1.example.com:${PEER_CHAINCODE_PORT}
    export CORE_PEER_CHAINCODELISTENADDRESS="0.0.0.0":${PEER_CHAINCODE_PORT}
    export CORE_PEER_GOSSIP_BOOTSTRAP=peer${PEER_NUM}.org1.example.com:${PEER_PORT}
    export CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer${PEER_NUM}.org1.example.com:${PEER_PORT}
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_OPERATIONS_LISTENADDRESS="0.0.0.0":${PEER_LISTEN_PORT}
    export CORE_PEER_FILESYSTEMPATH="${TEST_NETWORK_HOME}/production/peers/peer${PEER_NUM}.org1.example.com"
    export CORE_LEDGER_SNAPSHOTS_ROOTDIR="${TEST_NETWORK_HOME}/production/peers/peer${PEER_NUM}.org1.example.com/snapshots"
    # if [ ${PEER_NUM} -eq 0 ]; then
    #     ORDERER_CA=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    #     CHANNEL_NAME=channel0
    #     set -x
    #     ${BIN_DIR}/peer channel fetch 0 -c ${CHANNEL_NAME} ${TEST_NETWORK_HOME}/config/${CHANNEL_NAME}.block -o orderer0.example.com:7050 --ordererTLSHostnameOverride orderer0.example.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
    #     { set +x; } 2>/dev/null
    # fi

    nohup sh -c '${BIN_DIR}/peer node start' >${LOG_DIR}/peer${PEER_NUM}.log 2>&1 &
    pid=$!
    echo $pid >pid/peer${PEER_NUM}.pid
}

function main() {
    startPeer
}

main
