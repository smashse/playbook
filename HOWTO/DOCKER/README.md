# Instalar o DOCKER

**SO BASE:** UBUNTU

## Criar lista de extensões para VSCODE/Codium

```bash
echo "AmazonWebServices.aws-toolkit-vscode
GitHub.github-vscode-theme
GoogleCloudTools.cloudcode
HashiCorp.terraform
MS-CEINTL.vscode-language-pack-pt-BR
Pivotal.vscode-boot-dev-pack
Pivotal.vscode-spring-boot
betajob.modulestf
eamodio.gitlens
emroussel.atomize-atom-one-dark-theme
esbenp.prettier-vscode
formulahendry.docker-extension-pack
kde.breeze
ms-azuretools.vscode-azureterraform
ms-azuretools.vscode-docker
ms-kubernetes-tools.vscode-aks-tools
ms-kubernetes-tools.vscode-kubernetes-tools
ms-python.python
ms-vscode-remote.vscode-remote-extensionpack
ms-vscode.Theme-PredawnKit
ms-vscode.node-debug2
ms-vscode.vscode-typescript-next
ms-vscode.vscode-typescript-tslint-plugin
redhat.fabric8-analytics
redhat.java
redhat.vscode-knative
redhat.vscode-yaml
vscoss.vscode-ansible
zhuangtongfa.Material-theme" > vscode.list
```

## Instalar o VSCode

```bash
sudo snap install code --classic
```

```bash
for i in `cat vscode.list` ; do code --install-extension $i --force ; done
```

OU

## Instalar o Codium

```bash
sudo snap install codium --classic
```

```bash
for i in `cat vscode.list` ; do codium --install-extension $i --force ; done
```

## Instalar o Cockpit e Docker

### Instalar Docker

```bash
sudo snap install docker --classic
```

OU

```bash
sudo apt update
sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io
```

### Dar permissão de execução do Docker para o usuário atual

```bash
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

### Instalar Cockpit

```bash
sudo apt -y install cockpit
```

## Procurar imagens Docker

```bash
docker search ubuntu
```

## Adicionar imagem Docker

```bash
docker image pull ubuntu:latest
```

## Listar imagens Docker

```bash
docker image ls
```

## Remover imagem Docker

```bash
docker image rm ubuntu
```

## Criar container de imagem Docker

### Forma convencional

```bash
docker container create -t -i --name=ubuntu ubuntu
docker container start ubuntu
docker container attach ubuntu
docker container rm ubuntu
```

OU

### Forma simples

```bash
docker container create -t -i --name=ubuntu ubuntu
docker container start -a -i ubuntu
```

OU

### Forma extremamente simples acessando o bash

```bash
docker container run -i --name=ubuntu -t ubuntu /bin/bash
```

## Conectar ao container Docker

```bash
docker container attach ubuntu
```

## Instalar o Nginx dentro do container

```bash
apt update && apt -y install nginx && apt -y autoremove && apt -y clean
```

```bash
echo "daemon off;" >> /etc/nginx/nginx.conf
```

```bash
echo "sh /etc/init.d/nginx start" > /etc/rc.local
```

```bash
chmod 777 /etc/rc.local
```

**CTRL**+**P**

**CTR**+**Q**

## Inicializar o Nginx

```bash
docker container exec ubuntu sh /etc/rc.local
```

## Verificar os containers

```bash
docker container ps -a
```

## Criar imagem para o Ubuntu com Nginx

```bash
docker container commit ubuntu ubuntu-nginx
```

## Criar container utilizando a imagem ubuntu-nginx

```bash
docker container run -d --restart unless-stopped -p 8080:80 --name=ubuntu-web000 -t ubuntu-nginx
```

## Remover container de imagem Docker

```bash
docker container rm ubuntu -f
```

## Utilizar Dockerfiles

```bash
mkdir -p /opt/projects/ubuntu/nginx
```

```bash
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

```bash
cd /opt/projects/ubuntu/nginx/
```

```bash
docker image build -t ubuntu-nginx:latest .
```

```bash
docker container run -d --restart unless-stopped -p 8081:80 --name=ubuntu-web001 -t ubuntu-nginx:latest
```

## Efetuar login no Registry

```bash
docker login
```

## Efetuar logout no Registry

```bash
docker logout
```

## Listar informações do DOCKER

```bash
docker info
```

## Criar uma TAG da imagem local para o Registry

```bash
docker image tag ubuntu-nginx:latest ubuntu-nginx:latest
```

## Efetuar o Push da imagem para o Registry

```bash
docker image push seuusuario/ubuntu-nginx:latest
```

## Remover imagens, containers, volumes e redes não utilizadas

```bash
docker system prune -a
```

## Remover todos os containers

```bash
docker container ps -a
docker container stop $(docker container ps -a -q)
docker container rm $(docker container ps -a -q)
```

## Remover todas as imagens

```bash
docker image ls -a
docker image rm $(docker image ls -a -q)
```

## Trabalhando com Nginx

### Forma convencional

```bash
docker container run -d --restart unless-stopped -p 10000:80 -i --name=nginx -t ubuntu:latest /bin/bash
```

```bash
docker container run -d --restart unless-stopped -p 9091:8000 --name whoami01 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped -p 9092:8000 --name whoami02 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped -p 9093:8000 --name whoami03 -t jwilder/whoami:latest
```

```bash
docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx whoami01 whoami02 whoami03
```

```bash
docker container attach nginx
```

```bash
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

```bash
docker network create --subnet=172.18.0.0/16 network_teste
```

```bash
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.90 -p 10000:80 -i --name=nginx -t ubuntu:latest /bin/bash
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.91 -p 9091:8000 --name whoami01 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.92 -p 9092:8000 --name whoami02 -t jwilder/whoami:latest
docker container run -d --restart unless-stopped --net network_teste --ip 172.18.0.93 -p 9093:8000 --name whoami03 -t jwilder/whoami:latest
```

```bash
docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx whoami01 whoami02 whoami03
```

```bash
docker container attach nginx
```

```bash
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

```bash
mkdir -p nginx
cd nginx
```

### Dockerfile

```bash
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

```bash
nano -c docker-compose.yml
```

```yaml
version: "3.0"

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

```bash
sudo apt -y install docker-compose
```

#### Criar e iniciar contêineres

```bash
docker-compose up -d
```

#### Analisar logs do Compose

```bash
docker-compose logs -f
```

#### Pare e remova contêineres, redes, imagens e volumes

```bash
docker-compose down
```

### Trabalhando com secrets

#### Iniciando o Docker Swarm

```bash
docker swarm leave -f
docker swarm init
```

#### Criando secrets

```bash
openssl rand -base64 20 | docker secret create mysql_root_password - > secret.txt
openssl rand -base64 20 | docker secret create mysql_password - >> secret.txt
```

#### Listar secrets

```bash
docker secret ls
```

#### Criar rede privada

```bash
docker network create -d overlay mysql_private
```

#### Criar serviço MySQL

```bash
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

```bash
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

```bash
docker service ls
```

```bash
docker service ps wordpress mysql
```
