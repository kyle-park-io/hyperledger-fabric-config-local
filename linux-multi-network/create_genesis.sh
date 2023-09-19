#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -s $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"
export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config/common

function createGenesisBlock() {
    echo "Generating channel genesis block"
    set -x
    ${BIN_DIR}/configtxgen -profile OrgsOrdererGenesis -outputBlock ${TEST_NETWORK_HOME}/channel-artifacts/genesis.block -channelID system-channel
    res=$?
    { set +x; } 2>/dev/null
}

createGenesisBlock
