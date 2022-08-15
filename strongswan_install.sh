SUBNET="10.10.10.0/24"
DOMAIN="vpn.domain.com"
PRIVATE_KEY="server-key.pem"
CERT="server-cert.pem"
ACCOUNTS="test:testpassword test2:password2"
INTERFACE="eth0"

#Install strongswan
sudo apt update
sudo apt --yes install strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins

# Setup firewall
sudo ufw allow OpenSSH
sudo ufw allow 500,4500/udp
sudo cp /etc/ufw/before.rules{,.original}
sudo sed -i "1i*nat\\n\
-A POSTROUTING -s 10.10.10.0/24 -o $INTERFACE -m policy --pol ipsec --dir out -j ACCEPT\\n\
-A POSTROUTING -s 10.10.10.0/24 -o $INTERFACE -j MASQUERADE\\n\
COMMIT\\n\
\\n\
*mangle\\n\
-A FORWARD --match policy --pol ipsec --dir in -s $SUBNET -o $INTERFACE -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360\\n\
COMMIT" /etc/ufw/before.rules
sudo sed -i "/^# End required lines.*/a\
-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s $SUBNET -j ACCEPT\\n\
-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d $SUBNET -j ACCEPT" /etc/ufw/before.rules
sudo cp /etc/ufw/sysctl.conf{,.original}
echo 'net/ipv4/ip_forward=1
net/ipv4/conf/all/accept_redirects=0
net/ipv4/conf/all/send_redirects=0
net/ipv4/ip_no_pmtu_disc=1' | sudo tee -a /etc/ufw/sysctl.conf >/dev/null
sudo ufw disable
sudo ufw --force enable

# Import key and cert
sudo cp $PRIVATE_KEY /etc/ipsec.d/private/server-key.pem
sudo cp $CERT /etc/ipsec.d/certs/server-cert.pem

# Configure strongswan
sudo mv /etc/ipsec.conf{,.original}
echo "config setup
    charondebug=\"ike 1, knl 1, cfg 0\"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=@$DOMAIN
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=$SUBNET
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightsourceip=$SUBNET
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
    eap_identity=%identity
    ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
    esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!" | sudo tee /etc/ipsec.conf >/dev/null
    
#Configure accounts
echo ": RSA \"server-key.pem\"" | sudo tee -a /etc/ipsec.secrets >/dev/null
for x in $ACCOUNTS
do
    pair=(${x//:/ })
    echo "${pair[0]} : EAP \"${pair[1]}\"" | sudo tee -a /etc/ipsec.secrets >/dev/null
done

#Initialize strongswan
sudo systemctl restart strongswan-starter
