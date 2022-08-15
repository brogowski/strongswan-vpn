# Setup scripts for homebrew VPN host with strongswan (based on Ubuntu 20.04)

## `generate_vpn_keys.sh`
Script for generating self-signed certificate and encryption keys

### Variables:

- `CERT_NAME` - name for certificate ex: `VPN root CN`
- `DOMAIN` - domain name ex: `vpn.mydomain.com`

## `strongswan_install.sh`
Script for installing strongswan, setting login:password combos and configuring firewall

### Variables:

- `SUBNET` - subnet range for VPN clients ex: `10.10.10.0/24`
- `DOMAIN` - domain name ex: `vpn.mydomain.com`
- `PRIVATE_KEY` - path to private encryption key default: `server-key.pem`
- `CERT` -  path to certificate default: `server-cert.pem`
- `ACCOUNTS` - username:password list of accounts to setup ex: `test:testpassword test2:password2`
- `INTERFACE` - interface name for firewall configuration default: `eth0`

## `setup_vpn.sh`
Combination of 2 above with no `sudo` statements
Uses variables from both scripts above

## Links
Based on tutorial from Digital Ocean: [HERE](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-20-04)
