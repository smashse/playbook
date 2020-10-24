#!/bin/bash
echo "inicializa o cluster swarm"
docker container ps -a
docker container stop $(docker container ps -a -q)
docker container rm $(docker container ps -a -q)
docker system prune -a -f
docker volume prune -f
docker swarm leave -f
docker swarm init
openssl rand -base64 20 | docker secret create mysql_root_password -
openssl rand -base64 20 | docker secret create mysql_password -
docker stack deploy -c docker-compose.yml wordpress
docker stack services wordpress
echo "wordpress rodando localhost:10000"
