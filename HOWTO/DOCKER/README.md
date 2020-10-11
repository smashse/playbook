# Instalar o DOCKER

**SO BASE:** UBUNTU

## Instalar o Atom

```bash
sudo snap install atom --classic
```

```bash
apm install linter-ansible-linting
apm install linter-ansible-syntax
apm install linter-terraform-syntax
apm install linter-kubectl
apm install language-ansible
apm install language-terraform
apm install language-docker
apm install atom-beautify
```

## Instalar o Cockpit e Docker

```bash
sudo snap install docker --classic
```

OU

```bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

```bash
sudo apt install -y cockpit
```

```bash
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

## Procurar imagens Docker

```bash
sudo docker search ubuntu
```

## Adicionar imagem Docker

```bash
sudo docker pull ubuntu:latest
```

## Listar imagem Docker

```bash
sudo docker image ls
```

## Remover imagem Docker

```bash
sudo docker image rm ubuntu
```

## Criar container de imagem Docker

### Forma convencional

```bash
sudo docker container create -t -i --name=ubuntu ubuntu
sudo docker container start ubuntu
sudo docker container attach ubuntu
```

OU

### Forma simples

```bash
sudo docker create -t -i --name=ubuntu ubuntu
sudo docker start -a -i ubuntu
```

OU

### Forma extremamente simples acessando o bash

```bash
sudo docker run -i --name=ubuntu -t ubuntu /bin/bash
```

## Conectar ao container de imagem Docker

```bash
sudo docker attach ubuntu
```

## Instalar o Nginx dentro do container

```bash
apt update && apt install -y nginx && apt autoremove -y && apt clean -y
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
sudo docker exec ubuntu-nginx sh /etc/rc.local
```

## Verificar os containers

```bash
sudo docker ps -a
```

## Criar imagem para o Ubuntu com Nginx

```bash
sudo docker commit ubuntu ubuntu-nginx
```

## Criar container utilizando a imagem ubuntu-nginx

```bash
sudo docker run -d --restart unless-stopped -p 8080:80 --memory=64M --name=ubuntu-web001 -t ubuntu-nginx
```

## Remover container de imagem Docker

```bash
sudo docker container rm ubuntu -f
```

## Utilizar Dockerfiles

```bash
mkdir -p /opt/projects/ubuntu/nginx
```

```bash
nano  -c /opt/projects/ubuntu/nginx/Dockerfile
```

```docker
    FROM ubuntu:18.04

    MAINTAINER Admin

    RUN apt update \
        && apt install -y nginx \
        && apt autoremove -y \
        && apt clean -y \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
        && echo "daemon off;" >> /etc/nginx/nginx.conf

    EXPOSE 80
    CMD ["nginx"]
```

```bash
cd /opt/projects/ubuntu/nginx/
```

```bash
docker build -t ubuntu-nginx:latest .
```

```bash
docker run -d --restart unless-stopped -p 8081:80 --memory=64M --name=ubuntu-web001 -t ubuntu-nginx:latest
```

## Efetuar login no Registry

```bash
sudo docker login
```

## Listar informações do DOCKER

```bash
sudo docker registry ls
```

## Criar uma TAG da imagem local para o Registry

```bash
sudo docker tag gitops-ubuntu:0.1 seuusuario/gitops-ubuntu:0.1
```

## Efetuar o Push da imagem para o Registry

```bash
sudo docker push seuusuario/gitops-ubuntu:0.1
```
