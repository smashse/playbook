#!/bin/bash
echo "inicializa o cluster swarm"
docker swarm init
docker stack deploy -c docker-compose.yml nginx
docker stack services nginx
echo "nginx rodando localhost:10000"
