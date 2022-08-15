sudo apt update
sudo apt --yes install strongswan-pki

CERT_NAME="VPN root CA"
DOMAIN="vpn.domain.com"

pki --gen --type rsa --size 4096 --outform pem > ca-key.pem
pki --self --ca --lifetime 3650 --in ca-key.pem \
    --type rsa --dn "CN=$CERT_NAME" --outform pem > ca-cert.pem
    
pki --gen --type rsa --size 4096 --outform pem > server-key.pem
pki --pub --in server-key.pem --type rsa \
    | pki --issue --lifetime 1825 \
        --cacert ca-cert.pem \
        --cakey ca-key.pem \
        --dn "CN=$DOMAIN" --san $DOMAIN \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  server-cert.pem
