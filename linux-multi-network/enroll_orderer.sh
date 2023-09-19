#!/bin/bash
export TEST_NETWORK_HOME=$(dirname $(realpath -s $0))
export BIN_DIR="${TEST_NETWORK_HOME}/bin"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

function createOrderer() {
    for var in {0..2}; do
        if [ ${var} -eq 0 ]; then
            mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com

            export FABRIC_CA_CLIENT_HOME=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com

            # # ca client
            set -x
            ${BIN_DIR}/fabric-ca-client enroll -u https://admin:adminpw@ca:7054 --caname ca --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
            { set +x; } 2>/dev/null

            # # config
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
                OrganizationalUnitIdentifier: orderer' >${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml
        fi

        # # orderer node
        # register orderer
        echo Registering orderer${var}
        set -x
        ${BIN_DIR}/fabric-ca-client register --caname ca --id.name orderer${var} --id.secret orderer${var}pw --id.type orderer --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
        { set +x; } 2>/dev/null

        # get msp
        set -x
        ${BIN_DIR}/fabric-ca-client enroll -u https://orderer${var}:orderer${var}pw@ca:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/msp --csr.hosts chN.orderer${var}.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
        { set +x; } 2>/dev/null
        cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/msp/config.yaml

        # get tls
        set -x
        ${BIN_DIR}/fabric-ca-client enroll -u https://orderer${var}:orderer${var}pw@ca:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls --enrollment.profile tls --csr.hosts chN.orderer${var}.example.com --csr.hosts localhost --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
        { set +x; } 2>/dev/null

        # # make crt files
        # ca public
        cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/ca.crt
        # node public
        cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/signcerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/server.crt
        # node private
        cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/keystore/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/server.key

        # tls-ca public -> msp
        mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/msp/tlscacerts
        cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
        # tls-ca public -> common msp
        mkdir -p ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/tlscacerts
        cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer${var}.example.com/tls/tlscacerts/* ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem

        # # account
        # register admin
        set -x
        ${BIN_DIR}/fabric-ca-client register --caname ca --id.name orderer${var}Admin --id.secret orderer${var}Adminpw --id.type admin --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
        { set +x; } 2>/dev/null

        if [ ${var} -eq 0 ]; then
            # get tls
            set -x
            ${BIN_DIR}/fabric-ca-client enroll -u https://orderer${var}Admin:orderer${var}Adminpw@ca:7054 --caname ca -M ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp --tls.certfiles ${TEST_NETWORK_HOME}/organizations/fabric-ca-server/tls-cert.pem
            { set +x; } 2>/dev/null
            cp ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/msp/config.yaml ${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml
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

createOrderer
