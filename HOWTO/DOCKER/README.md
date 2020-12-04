# Instalar o DOCKER

**SO BASE:** UBUNTU

## Instalar o VSCode

```shell
sudo snap install code --classic
```

```shell
code --install-extension AmazonWebServices.aws-toolkit-vscode
code --install-extension GitHub.github-vscode-theme
code --install-extension GoogleCloudTools.cloudcode
code --install-extension HashiCorp.terraform
code --install-extension MS-CEINTL.vscode-language-pack-pt-BR
code --install-extension Pivotal.vscode-boot-dev-pack
code --install-extension Pivotal.vscode-spring-boot
code --install-extension eamodio.gitlens
code --install-extension esbenp.prettier-vscode
code --install-extension formulahendry.docker-extension-pack
code --install-extension kde.breeze
code --install-extension ms-azuretools.vscode-azureterraform
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-aks-tools
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension ms-python.python
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code --install-extension ms-vscode.Theme-PredawnKit
code --install-extension ms-vscode.node-debug2
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension ms-vscode.vscode-typescript-tslint-plugin
code --install-extension redhat.fabric8-analytics
code --install-extension redhat.java
code --install-extension redhat.vscode-knative
code --install-extension redhat.vscode-yaml
code --install-extension vscoss.vscode-ansible
```

## Instalar o Cockpit e Docker

### Instalar Docker

```shell
sudo snap install docker --classic
```

OU

```shell
sudo apt update
sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io
```

### Dar permissão de execução do Docker para o usuário atual

```shell
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

### Instalar Cockpit

```shell
sudo apt -y install cockpit
```

## Procurar imagens Docker

```shell
docker search ubuntu
```

## Adicionar imagem Docker

```shell
docker image pull ubuntu:latest
```

## Listar imagens Docker

```shell
docker image ls
```

## Remover imagem Docker

```shell
docker image rm ubuntu
```

## Criar container de imagem Docker

### Forma convencional

```shell
docker container create -t -i --name=ubuntu ubuntu
docker container start ubuntu
docker container attach ubuntu
docker container rm ubuntu
```

OU

### Forma simples

```shell
docker container create -t -i --name=ubuntu ubuntu
docker container start -a -i ubuntu
```

OU

### Forma extremamente simples acessando o bash

```shell
docker container run -i --name=ubuntu -t ubuntu /bin/bash
```

## Conectar ao container Docker

```shell
docker container attach ubuntu
```

## Instalar o Nginx dentro do container

```shell
apt update && apt -y install nginx && apt -y autoremove && apt -y clean
```

```shell
echo "daemon off;" >> /etc/nginx/nginx.conf
```

```shell
echo "sh /etc/init.d/nginx start" > /etc/rc.local
```

```shell
chmod 777 /etc/rc.local
```

**CTRL**+**P**

**CTR**+**Q**

## Inicializar o Nginx

```shell
docker container exec ubuntu sh /etc/rc.local
```

## Verificar os containers

```shell
docker container ps -a
```

## Criar imagem para o Ubuntu com Nginx

```shell
docker container commit ubuntu ubuntu-nginx
```

## Criar container utilizando a imagem ubuntu-nginx

```shell
docker container run -d --restart unless-stopped -p 8080:80 --name=ubuntu-web000 -t ubuntu-nginx
```

## Remover container de imagem Docker

```shell
docker container rm ubuntu -f
```

## Utilizar Dockerfiles

```shell
mkdir -p /opt/projects/ubuntu/nginx
```

```shell
nano  -c /opt/projects/ubuntu/nginx/Dockerfile
```

```docker
FROM ubuntu:20.04

LABEL author="Admin"

RUN apt-get update \
    && apt-get -y install nginx \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt-get/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx"]
```

```shell
cd /opt/projects/ubuntu/nginx/
```

```shell
docker image build -t ubuntu-nginx:latest .
```

```shell
docker container run -d --restart unless-stopped -p 8081:80 --name=ubuntu-web001 -t ubuntu-nginx:latest
```

## Efetuar login no Registry

```shell
docker login
```

## Efetuar logout no Registry

```shell
docker logout
```

## Listar informações do DOCKER

```shell
docker info
```

## Criar uma TAG da imagem local para o Registry

```shell
docker image tag ubuntu-nginx:latest ubuntu-nginx:latest
```

## Efetuar o Push da imagem para o Registry

```shell
docker image push seuusuario/ubuntu-nginx:latest
```

## Remover imagens, containers, volumes e redes não utilizadas

```shell
docker system prune -a
```

## Remover todos os containers

```shell
docker container ps -a
docker container stop $(docker container ps -a -q)
docker container rm $(docker container ps -a -q)
```

## Remover todas as imagens

```shell
docker image ls -a
docker image rm $(docker image ls -a -q)
```

## Trabalhando com Nginx

### Forma convencional

```shell
docker container run -d --restart unless-stopped -p 10000:80 -i --name=nginx -t ubuntu:latest /bin/bash
```

```shell
docker container run -d --restart unless-stopped -p 9091:8000 --name whoami01 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped -p 9092:8000 --name whoami02 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped -p 9093:8000 --name whoami03 -t jwilder/whoami:latest
```

```shell
docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx whoami01 whoami02 whoami03
```

```shell
docker container attach nginx
```

```shell
apt update && apt -y install nano nginx
echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        server_name _;
        location / {
                proxy_pass http://nginx;

        }
}
upstream nginx {
server 172.17.0.3:8000;
server 172.17.0.4:8000;
server 172.17.0.5:8000;
}" > /etc/nginx/sites-available/nginx
ln -sf /etc/nginx/sites-available/nginx /etc/nginx/sites-enabled/nginx
rm -rf /etc/nginx/sites-enabled/default
echo "daemon off;" >> /etc/nginx/nginx.conf
service nginx restart
```

### Forma simples

```shell
docker network create --subnet=172.18.0.0/16 network_teste
```

```shell
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.90 -p 10000:80 -i --name=nginx -t ubuntu:latest /bin/bash
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.91 -p 9091:8000 --name whoami01 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.92 -p 9092:8000 --name whoami02 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.93 -p 9093:8000 --name whoami03 -t jwilder/whoami:latest
```

```shell
docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx whoami01 whoami02 whoami03
```

```shell
docker container attach nginx
```

```shell
apt update && apt -y install nano nginx
echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        server_name _;
        location / {
                proxy_pass http://nginx;

        }
}
upstream nginx {
server 172.18.0.91:8000;
server 172.18.0.92:8000;
server 172.18.0.93:8000;
}" > /etc/nginx/sites-available/nginx
ln -sf /etc/nginx/sites-available/nginx /etc/nginx/sites-enabled/nginx
rm -rf /etc/nginx/sites-enabled/default
echo "daemon off;" >> /etc/nginx/nginx.conf
service nginx restart
```

### Forma Compose

```shell
mkdir -p nginx
cd nginx
```

### Dockerfile

```shell
nano -c Dockerfile
```

```docker
FROM ubuntu:latest

LABEL author="Admin"

RUN apt-get update \
    && apt-get -y install nginx \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt-get/lists/* /tmp/* /var/tmp/* \
    && echo "server { \
            listen 80 default_server; \
            listen [::]:80 default_server; \
            root /var/www/html; \
            index index.html index.htm index.nginx-debian.html; \
            server_name _; \
            location / { \
                    proxy_pass http://nginx; \
            } \
    } \
    upstream nginx { \
    server 172.18.0.91:8000; \
    server 172.18.0.92:8000; \
    server 172.18.0.93:8000; \
    }" > /etc/nginx/sites-available/nginx \
    && ln -sf /etc/nginx/sites-available/nginx /etc/nginx/sites-enabled/nginx \
    && rm -rf /etc/nginx/sites-enabled/default \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx"]
```

### Compose

```shell
nano -c docker-compose.yml
```

```yaml
version: '3.0'

networks:
   network_compose:
     driver: bridge
     ipam:
         config:
           - subnet: 172.18.0.0/16

services:
   nginx:
     build: .
     ports:
       - "10000:80"
     restart: always
     networks:
         network_compose:
             ipv4_address: 172.18.0.90

   whoami01:
     image: jwilder/whoami:latest
     ports:
       - "9091:8000"
     restart: always
     networks:
         network_compose:
             ipv4_address: 172.18.0.91

   whoami02:
     image: jwilder/whoami:latest
     ports:
       - "9092:8000"
     restart: always
     networks:
         network_compose:
             ipv4_address: 172.18.0.92

   whoami03:
     image: jwilder/whoami:latest
     ports:
       - "9093:8000"
     restart: always
     networks:
         network_compose:
             ipv4_address: 172.18.0.93
```

### Crie e execute seu aplicativo com o Compose

```shell
sudo apt -y install docker-compose
```

#### Criar e iniciar contêineres

```shell
docker-compose up -d
```

#### Analisar logs do Compose

```shell
docker-compose logs -f
```

#### Pare e remova contêineres, redes, imagens e volumes

```shell
docker-compose down
```

### Trabalhando com secrets

#### Iniciando o Docker Swarm

```shell
docker swarm leave -f
docker swarm init
```

#### Criando secrets

```shell
openssl rand -base64 20 | docker secret create mysql_root_password - > secret.txt
openssl rand -base64 20 | docker secret create mysql_password - >> secret.txt
```

#### Listar secrets

```shell
docker secret ls
```

#### Criar rede privada

```shell
docker network create -d overlay mysql_private
```

#### Criar serviço MySQL

```shell
docker service create \
     --name mysql \
     --replicas 1 \
     --network mysql_private \
     --mount type=volume,source=mydata,destination=/var/lib/mysql \
     --secret source=mysql_root_password,target=mysql_root_password \
     --secret source=mysql_password,target=mysql_password \
     -e MYSQL_ROOT_PASSWORD_FILE="/run/secrets/mysql_root_password" \
     -e MYSQL_PASSWORD_FILE="/run/secrets/mysql_password" \
     -e MYSQL_USER="wordpress" \
     -e MYSQL_DATABASE="wordpress" \
     mysql:latest
```

#### Criar serviço Wordpress

```shell
docker service create \
     --name wordpress \
     --replicas 1 \
     --network mysql_private \
     --publish published=10000,target=80 \
     --mount type=volume,source=wpdata,destination=/var/www/html \
     --secret source=mysql_password,target=wp_db_password,mode=0400 \
     -e WORDPRESS_DB_USER="wordpress" \
     -e WORDPRESS_DB_PASSWORD_FILE="/run/secrets/wp_db_password" \
     -e WORDPRESS_DB_HOST="mysql:3306" \
     -e WORDPRESS_DB_NAME="wordpress" \
     wordpress:latest
```

#### Verificar se os containers estão ativos

```shell
docker service ls
```

```shell
docker service ps wordpress mysql
```
