#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -s $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/common

CHANNEL_NAME=${1}
: ${CHANNEL_NAME:="channel0"}
PROFILE_NAME=${2}
: ${PROFILE_NAME:="OrgsChannel"}

function createChannelTx() {
    echo "Generating channel tx"
    set -x
    ${BIN_DIR}/configtxgen -profile ${PROFILE_NAME} -outputCreateChannelTx ${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
    res=$?
    { set +x; } 2>/dev/null
}

createChannelTx
