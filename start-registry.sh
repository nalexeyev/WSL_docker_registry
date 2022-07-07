#!/usr/bin/env bash

set -e

docker-compose -p docker-registry-wsl up --detach

sleep 2
docker-compose ls

echo -e "\nBy default registry is available at https://wsl:5000 (check https://wsl:5000/v2/_catalog in your browser)"
echo -e "and registry-ui is available at http://wsl:8081 (not https)\n"
read -t5 -n 1 -s -r -p "Wait 5 seconds or press any key to finish...."
