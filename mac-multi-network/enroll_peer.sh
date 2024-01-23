#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -q $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

function createOrg1() {
    for var in {0..2}; do
        if [ ${var} -eq 0 ]; then
            mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/

            export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/

            Org1_address="fabric-ca-server/tls-cert.pem"

            # # ca client
            echo "Enrolling the CA admin"
            set -x
            # ${BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@ca:7054 --caname ca --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
            ${BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@ca:7054 --caname ca --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
            { set +x; } 2>/dev/null

            echo 'NodeOUs:
            Enable: true
            ClientOUIdentifier:
                Certificate: cacerts/ca-7054-ca.pem
                OrganizationalUnitIdentifier: client
            PeerOUIdentifier:
                Certificate: cacerts/ca-7054-ca.pem
                OrganizationalUnitIdentifier: peer
            AdminOUIdentifier:
                Certificate: cacerts/ca-7054-ca.pem
                OrganizationalUnitIdentifier: admin
            OrdererOUIdentifier:
                Certificate: cacerts/ca-7054-ca.pem
                OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml
        fi

        # # peer node
        # register peer
        echo Registering peer${var}
        set -x
        ${BIN_DIR}/fabric-ca-client register --caname ca --id.name peer${var} --id.secret peer${var}pw --id.type peer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
        { set +x; } 2>/dev/null

        # get msp
        set -x
        ${BIN_DIR}/fabric-ca-client enroll -u https://peer${var}:peer${var}pw@ca:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/msp --csr.hosts chN.peer${var}.org1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
        { set +x; } 2>/dev/null
        cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/msp/config.yaml

        # get tls
        set -x
        ${BIN_DIR}/fabric-ca-client enroll -u https://peer${var}:peer${var}pw@ca:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls --enrollment.profile tls --csr.hosts chN.peer${var}.org1.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
        { set +x; } 2>/dev/null

        # # make crt files
        # ca public
        cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/ca.crt
        # node public
        cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.crt
        # node private
        cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer${var}.org1.example.com/tls/server.key

        # tls-ca public -> msp
        mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts
        cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/tlscacerts/ca.crt
        # tls-ca public -> common msp
        mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca
        cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
        # msp-ca public -> common ca
        mkdir -p ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca
        cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/cacerts/* ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

        if [ ${var} -eq 0 ]; then
            # # account
            # register admin
            set -x
            ${BIN_DIR}/fabric-ca-client register --caname ca --id.name org1admin --id.secret org1adminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin",hf.Revoker=true' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
            { set +x; } 2>/dev/null

            # get tls
            echo "Generating the org admin msp"
            set -x
            ${BIN_DIR}/fabric-ca-client enroll -u https://org1admin:org1adminpw@ca:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
            { set +x; } 2>/dev/null
            cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml

            # register user
            set -x
            ${BIN_DIR}/fabric-ca-client register --caname ca --id.name user1 --id.secret user1pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
            { set +x; } 2>/dev/null

            # get tls
            set -x
            ${BIN_DIR}/fabric-ca-client enroll -u https://user1:user1pw@ca:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/${Org1_address}
            { set +x; } 2>/dev/null
            cp ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/config.yaml
        fi
    done
}

while :; do
    if [ ! -f "organizations/fabric-ca-server/tls-cert.pem" ]; then
        sleep 1
    else
        break
    fi
done

createOrg1
