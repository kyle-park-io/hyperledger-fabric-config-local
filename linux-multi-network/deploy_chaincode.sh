#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -s $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/peer

# tls
# export CORE_PEER_ADDRESS=chN.peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
# export CORE_PEER_TLS_CERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt
# export CORE_PEER_TLS_KEY_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
# export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
# export CORE_PEER_LOCALMSPID="Org1MSP"
export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

export CHAINCODE_INIT_REQUIRED=""
export CHAINCODE_END_POLICY=""
export CHAINCODE_COLL_CONFIG=""
export MAX_RETRY=5
export DELAY=2

function deployChaincode() {
    export CHANNEL_NAME=$1
    mkdir -p ${TEST_NETWORK_HOME}/log/${CHANNEL_NAME}

    CHAINCODE_NAME=$2
    CHAINCODE_VERSION=$3
    CHAINCODE_SEQUENCE=$4
    CHAINCODE_PATH=${TEST_NETWORK_HOME}/chaincode/chaincode/${CHAINCODE_NAME}
    CHAINCODE_PACKAGE_PATH=${TEST_NETWORK_HOME}/packages/${CHAINCODE_NAME}.tar.gz
    LOG_PATH=${LOG_DIR}/${CHANNEL_NAME}/${CHAINCODE_NAME}.log

    pushd ${CHAINCODE_PATH}
    GO111MODULE=on go mod vendor
    popd
    echo "Finished vendoring Go dependencies"

    set -x
    ${BIN_DIR}/peer lifecycle chaincode package ${CHAINCODE_PACKAGE_PATH} --path ${CHAINCODE_PATH} --lang "golang" --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION} >&${LOG_PATH}
    res=$?
    { set +x; } 2>/dev/null
    cat ${LOG_PATH}
    verifyResult $res "Chaincode packaging has failed"
    echo "Chaincode is packaged"

    # install
    for var in {0..2}; do
        PEER_PORT=$(((($var + 7) * 1000) + 51))
        # tls
        export CORE_PEER_ADDRESS=chN.peer${var}.org1.example.com:${PEER_PORT}
        export CORE_PEER_TLS_CERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.crt
        export CORE_PEER_TLS_KEY_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.key
        export CORE_PEER_TLS_ROOTCERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/ca.crt

        # set PEER_CONN_PARMS
        PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
        TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
        PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"

        if [ "$CHANNEL_NAME" == "ch1" ]; then
            # export CORE_PEER_LISTENADDRESS="0.0.0.0":${PEER_PORT}
            # export CORE_PEER_CHAINCODEADDRESS=chN.peer${PEER_NUM}.org1.example.com:${PEER_CHAINCODE_PORT}
            # export CORE_PEER_CHAINCODELISTENADDRESS="0.0.0.0":${PEER_CHAINCODE_PORT}
            # export CORE_PEER_GOSSIP_BOOTSTRAP=chN.peer${PEER_NUM}.org1.example.com:${PEER_PORT}
            # export CORE_PEER_GOSSIP_EXTERNALENDPOINT=chN.peer${PEER_NUM}.org1.example.com:${PEER_PORT}
            export CORE_PEER_LOCALMSPID="Org1MSP"
            # export CORE_OPERATIONS_LISTENADDRESS="0.0.0.0":${PEER_LISTEN_PORT}

            set -x
            ${BIN_DIR}/peer lifecycle chaincode install ${CHAINCODE_PACKAGE_PATH} >&${LOG_PATH}
            res=$?
            { set +x; } 2>/dev/null
            cat ${LOG_PATH}
            verifyResult $res "Chaincode installation on peer${var}.org1 has failed"
            echo "Chaincode is installed on peer${var}.org1"
        fi
    done

    # approveformyorg
    for var in {0..0}; do
        PEER_PORT=$(((($var + 7) * 1000) + 51))
        # tls
        export CORE_PEER_ADDRESS=chN.peer${var}.org1.example.com:${PEER_PORT}
        # export CORE_PEER_ADDRESS=peer${var}.org1.example.com:${PEER_PORT}
        export CORE_PEER_TLS_CERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.crt
        export CORE_PEER_TLS_KEY_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.key
        export CORE_PEER_TLS_ROOTCERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/ca.crt

        set -x
        ${BIN_DIR}/peer lifecycle chaincode queryinstalled >&${LOG_PATH}
        res=$?
        { set +x; } 2>/dev/null
        cat ${LOG_PATH}
        PACKAGE_ID=$(sed -n "/${CHAINCODE_NAME}_${CHAINCODE_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" ${LOG_PATH})
        verifyResult $res "Query installed on peer${var}.org1 has failed"
        echo "Query installed successful on peer${var}.org1 on channel"

        echo ${PACKAGE_ID}
        set -x
        ${BIN_DIR}/peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 --ordererTLSHostnameOverride chN.orderer0.example.com --tls --cafile $ORDERER_CA $PEER_CONN_PARMS --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --package-id ${PACKAGE_ID} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_PATH}
        res=$?
        { set +x; } 2>/dev/null
        cat ${LOG_PATH}
        verifyResult $res "Chaincode definition approved on peer${var}.org1 on channel '${CHANNEL_NAME}' failed"
        echo "Chaincode definition approved on peer${var}.org1 on channel '${CHANNEL_NAME}'"
    done

    # checkcommitreadiness
    for var in {0..2}; do
        PEER_PORT=$(((($var + 7) * 1000) + 51))
        # tls
        export CORE_PEER_ADDRESS=chN.peer${var}.org1.example.com:${PEER_PORT}
        export CORE_PEER_TLS_CERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.crt
        export CORE_PEER_TLS_KEY_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.key
        export CORE_PEER_TLS_ROOTCERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/ca.crt

        local rc=1
        local COUNTER=1
        # continue to poll
        # we either get a successful response, or reach MAX RETRY
        shift 3
        while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
            sleep $DELAY
            echo "Attempting to check the commit readiness of the chaincode definition on peer${var}.org1, Retry after $DELAY seconds."
            set -x
            ${BIN_DIR}/peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} --output json >&${LOG_PATH}
            res=$?
            { set +x; } 2>/dev/null
            let rc=0
            for var in "$@"; do
                grep "$var" ${LOG_PATH} &>/dev/null || let rc=1
            done
            COUNTER=$(expr $COUNTER + 1)
        done
        cat ${LOG_PATH}
        # if $rc -eq 0; then
        #     echo "Checking the commit readiness of the chaincode definition successful on peer${var}.org on channel '${CHANNEL_NAME}'"
        # else
        #     echo "After $MAX_RETRY attempts, Check commit readiness result on peer${var}.org1 is INVALID!"
        #     exit 1
        # fi
    done

    # commit
    for var in {0..0}; do
        PEER_PORT=$(((($var + 7) * 1000) + 51))
        # tls
        export CORE_PEER_ADDRESS=chN.peer${var}.org1.example.com:${PEER_PORT}
        export CORE_PEER_TLS_CERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.crt
        export CORE_PEER_TLS_KEY_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.key
        export CORE_PEER_TLS_ROOTCERT_FILE=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/ca.crt

        # while 'peer chaincode' command can get the orderer endpoint from the
        # peer (if join was successful), let's supply it directly as we know
        # it using the "-o" option
        set -x
        ${BIN_DIR}/peer lifecycle chaincode commit -o orderer0.example.com:7050 --ordererTLSHostnameOverride chN.orderer0.example.com --tls --cafile $ORDERER_CA $PEER_CONN_PARMS --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} ${CHAINCODE_INIT_REQUIRED} ${CHAINCODE_END_POLICY} ${CHAINCODE_COLL_CONFIG} >&${LOG_PATH}
        res=$?
        { set +x; } 2>/dev/null
        cat ${LOG_PATH}
        verifyResult $res "Chaincode definition commit failed on peer${var}.org1 on channel '${CHANNEL_NAME}' failed"
        echo "Chaincode definition committed on channel '${CHANNEL_NAME}'"

        EXPECTED_RESULT="Version: ${CHAINCODE_VERSION}, Sequence: ${CHAINCODE_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
        echo "Querying chaincode definition on peer${var}.org$ on channel '${CHANNEL_NAME}'..."
        local rc=1
        local COUNTER=1
        # continue to poll
        # we either get a successful response, or reach MAX RETRY
        while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
            sleep $DELAY
            echo "Attempting to Query committed status on peer${var}.org1, Retry after $DELAY seconds."
            set -x
            ${BIN_DIR}/peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} >&${LOG_PATH}
            res=$?
            { set +x; } 2>/dev/null
            if [ $res -eq 0 ]; then
                VALUE=$(cat ${LOG_PATH} | grep -o '^Version: '$CHAINCODE_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
            fi
            test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
            COUNTER=$(expr $COUNTER + 1)
        done
        cat ${LOG_PATH}
        if test $rc -eq 0; then
            echo "Query chaincode definition successful on peer${var}.org1 on channel '${CHANNEL_NAME}'"
        else
            echo "After $MAX_RETRY attempts, Query chaincode definition result on peer${var}.org1 is INVALID!"
            exit 1
        fi
    done

    PEER_CONN_PARMS=""
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
        echo -e "$2"
        exit 1
    fi
}

function main() {
    # ch1
    deployChaincode ch1 a 1.0 1
    deployChaincode ch1 b 1.0 1
    # ch2
    deployChaincode ch2 a 1.0 1
    deployChaincode ch2 b 1.0 1
}

main
