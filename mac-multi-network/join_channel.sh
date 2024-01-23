#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -q $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/peer
export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

DELAY="$2"
: ${DELAY:="3"}
MAX_RETRY="$3"
: ${MAX_RETRY:="5"}

function joinChannel() {
    CHANNEL_NAME=$1
    setPeer $2

    local rc=1
    local COUNTER=1
    ## Sometimes Join takes time, hence retry
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        set -x
        ${BIN_DIR}/peer channel join -b ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}.block >&${LOG_DIR}/peer${PEER_NUM}-${CHANNEL_NAME}.log
        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat ${LOG_DIR}/peer${PEER_NUM}-${CHANNEL_NAME}.log
    verifyResult $res "After $MAX_RETRY attempts, peer${PEER_NUM}.org1 has failed to join channel '$CHANNEL_NAME'"
}

function setPeer() {
    PEER_NUM=${1}
    PEER_PORT=$(((($PEER_NUM + 7) * 1000) + 51))
    PEER_LISTEN_PORT=$(((($PEER_NUM + 7) * 1000) + 445))
    PEER_CHAINCODE_PORT=$(((($PEER_NUM + 7) * 1000) + 52))

    export FABRIC_LOGGING_SPEC="INFO"
    # export FABRIC_LOGGING_SPEC="DEBUG"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_TLS_ENABLED=true
    # export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/msp
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export CORE_PEER_TLS_CERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/tls/server.crt
    export CORE_PEER_TLS_KEY_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/tls/server.key
    export CORE_PEER_TLS_ROOTCERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${PEER_NUM}.org1.example.com/tls/ca.crt
    export CORE_PEER_ID=peer${PEER_NUM}.org1.example.com
    # tls
    export CORE_PEER_ADDRESS=chN.peer${PEER_NUM}.org1.example.com:${PEER_PORT}
    export CORE_PEER_LISTENADDRESS="0.0.0.0":${PEER_PORT}
    export CORE_PEER_CHAINCODEADDRESS=chN.peer${PEER_NUM}.org1.example.com:${PEER_CHAINCODE_PORT}
    export CORE_PEER_CHAINCODELISTENADDRESS="0.0.0.0":${PEER_CHAINCODE_PORT}
    export CORE_PEER_GOSSIP_BOOTSTRAP=chN.peer${PEER_NUM}.org1.example.com:${PEER_PORT}
    export CORE_PEER_GOSSIP_EXTERNALENDPOINT=chN.peer${PEER_NUM}.org1.example.com:${PEER_PORT}
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_OPERATIONS_LISTENADDRESS="0.0.0.0":${PEER_LISTEN_PORT}
    export CORE_PEER_FILESYSTEMPATH="${TEST_NETWORK_HOME}/production/peers/peer${PEER_NUM}.org1.example.com"
    export CORE_LEDGER_SNAPSHOTS_ROOTDIR="${TEST_NETWORK_HOME}/production/peers/peer${PEER_NUM}.org1.example.com/snapshots"
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

joinChannel ch1 0
joinChannel ch1 1
joinChannel ch1 2
joinChannel ch2 0
joinChannel ch2 1
joinChannel ch2 2