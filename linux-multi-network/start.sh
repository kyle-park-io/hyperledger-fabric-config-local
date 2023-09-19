./clear.sh
./start_ca.sh
sleep 1
./enroll_orderer.sh
./enroll_peer.sh
sleep 1
./create_genesis.sh
./create_tx.sh ch1
./create_tx.sh ch2
sleep 1
./start_orderer.sh 0
sleep 1
./start_orderer.sh 1
sleep 1
./start_orderer.sh 2
sleep 1
./start_peer.sh 0
sleep 1
./start_peer.sh 1
sleep 1
./start_peer.sh 2
sleep 1
./create_channel.sh
sleep 1
./join_channel.sh
sleep 1
./setAnchorPeer.sh
sleep 1
./deploy_chaincode.sh
sleep 1
./deploy_token.sh