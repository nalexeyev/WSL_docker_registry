#!/usr/bin/env bash

set -e

openssl version
read -n 1 -s -r -p "OpenSSL version should be not less than 1.1.1. Press any key to continue...."

openssl genrsa -out wsl_ca.key 2048
openssl req -new -x509 -days 365 -key wsl_ca.key -subj "/C=UA/ST=UA/L=Kyiv/O=Cool DevOps/CN=WSL Root CA" -out wsl_ca.crt
openssl req -newkey rsa:2048 -nodes -keyout wsl.key -subj "/C=UA/ST=UA/L=Kyiv/O=Cool DevOps/CN=*.wsl" -out wsl.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:wsl,DNS:wsl.local,DNS:dns_name_of.my-mocked-corporate-registry.net,IP:192.168.37.2") -days 3650 -in wsl.csr -CA wsl_ca.crt -CAkey wsl_ca.key -CAcreateserial -out wsl.crt
openssl x509  -noout -text -in ./wsl.crt
read -n 1 -s -r -p "Press any key to continue. Then find wsl_ca in the list and enable it."

sudo cp -v wsl_ca.crt /usr/share/ca-certificates/
sudo dpkg-reconfigure ca-certificates
sudo update-ca-certificates
sudo mkdir -p /opt/docker-registry/certs/
sudo chmod -R 777 /opt/docker-registry/
cp wsl.key -v /opt/docker-registry/certs/wsl.key
cp wsl.crt -v /opt/docker-registry/certs/wsl.crt

# Registry config example can be taken by the following link:
# https://raw.githubusercontent.com/distribution/distribution/main/cmd/registry/config-example.yml
cp config.yml -v /opt/docker-registry/config.yml

echo "***********************************************************************************************"
echo -e "\nadd --insecure-registry wsl:5000 parameter to dockerd launch command like the following:"
echo -e "sudo dockerd -H tcp://0.0.0.0 --insecure-registry wsl:5000 > /dev/null 2>&1 & \n"
echo "***********************************************************************************************"
read -n 1 -s -r -p "Press any key to continue. Then restart docker to accept new certificates"
echo .

: << 'SKIP'
docker run -d --restart=always -p 5000:443  --name registry     -v /opt/docker-registry/certs:/certs -v /opt/docker-registry:/var/lib/registry -e REGISTRY_HTTP_ADDR=0.0.0.0:443 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/wsl.crt -e REGISTRY_HTTP_TLS_KEY=/certs/wsl.key -e REGISTRY_STORAGE_DELETE_ENABLED=true registry:2
docker run -d --restart=always -p 8081:80   --name registry-ui  -e REGISTRY_HOST=wsl -e REGISTRY_PORT=5000 -e REGISTRY_PROTOCOL=https -e SSL_VERIFY=false -e ALLOW_REGISTRY_LOGIN=true -e REGISTRY_ALLOW_DELETE=true --add-host=wsl:192.168.37.2 parabuzzle/craneoperator:latest
SKIP