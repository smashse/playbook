#!/bin/bash
echo "inicializa o cluster swarm"
docker swarm init
docker stack deploy -c docker-compose.yml wordpress
docker stack services wordpress
echo "wordpress rodando localhost:10000"
