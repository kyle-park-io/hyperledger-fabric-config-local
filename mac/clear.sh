#!/bin/bash

# log
rm -rf log
mkdir log

# packages
rm -rf packages
mkdir packages

# chaincode
rm -rf chaincode
mkdir chaincode

# production
rm -rf production

# channel-artifacts
rm -rf channel-artifacts

# organizations
rm -rf organizations

# pid
rm -rf pid
mkdir pid

docker rm -f $(docker ps -aq)
docker rmi $(docker images -q --filter "reference=dev-*")

# ca
PROCESS=$(pgrep fabric-ca)
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi

# orderer
PROCESS=$(pgrep orderer)
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi

# peer
PROCESS=$(pgrep peer)
if [ -n "$PROCESS" ]; then
    echo "kill $PROCESS"
    kill -9 $PROCESS
fi
