#!/bin/bash
echo "inicializa o cluster swarm"
docker container ps -a
docker container stop $(docker container ps -a -q)
docker container rm $(docker container ps -a -q)
docker system prune -a -f
docker volume prune -f
docker swarm leave -f
docker swarm init
docker stack deploy -c docker-compose.yml nginx
docker stack services nginx
echo "nginx rodando localhost:10000"
