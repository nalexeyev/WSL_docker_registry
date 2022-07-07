#!/usr/bin/env bash

set -e

openssl version
read -n 1 -s -r -p "OpenSSL version should be not less than 1.1.1. Press any key to continue...."
openssl genrsa -out wsl_ca.key 2048
openssl req -new -x509 -days 365 -key wsl_ca.key -subj "/C=UA/ST=UA/L=Kyiv/O=EPAM DevOps/CN=WSL Root CA" -out wsl_ca.crt
openssl req -newkey rsa:2048 -nodes -keyout wsl.key -subj "/C=UA/ST=UA/L=Kyiv/O=EPAM DevOps/CN=*.wsl" -out wsl.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:wsl,DNS:wsl.local,IP:192.168.37.2") -days 3650 -in wsl.csr -CA wsl_ca.crt -CAkey wsl_ca.key -CAcreateserial -out wsl.crt
openssl x509  -noout -text -in ./wsl.crt
sudo cp -v wsl_ca.crt /usr/share/ca-certificates/
read -n 1 -s -r -p "Find wsl_ca in the list and enable it. Press any key to continue...."
sudo dpkg-reconfigure ca-certificates
sudo update-ca-certificates
sudo mkdir -p /opt/docker-registry/certs/
sudo chmod -R 777 /opt/docker-registry/certs/
cp wsl.key -v /opt/docker-registry/certs/wsl.key
cp wsl.crt -v /opt/docker-registry/certs/wsl.crt

#docker run -d --restart=always -p 5000:443  --name registry     -v /opt/docker-registry/certs:/certs -v /opt/docker-registry:/var/lib/registry -e REGISTRY_HTTP_ADDR=0.0.0.0:443 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/wsl.crt -e REGISTRY_HTTP_TLS_KEY=/certs/wsl.key -e REGISTRY_STORAGE_DELETE_ENABLED=true registry:2
#docker run -d --restart=always -p 8081:80   --name registry-ui  -e REGISTRY_HOST=wsl -e REGISTRY_PORT=5000 -e REGISTRY_PROTOCOL=https -e SSL_VERIFY=false -e ALLOW_REGISTRY_LOGIN=true -e REGISTRY_ALLOW_DELETE=true --add-host=wsl:192.168.37.2 parabuzzle/craneoperator:latest
