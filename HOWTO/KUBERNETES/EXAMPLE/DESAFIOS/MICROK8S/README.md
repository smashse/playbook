# _**Desafio:** Criar um deployment com nginx e disponibilizar por meio dele um arquivo "teste.tar" contendo os arquivos {A,B,C}.txt._

## Criar arquivo tar

```shell
mkdir teste
touch teste/{A.txt,B.txt,C.txt}
tar -c teste -f teste.tar
tar -tf teste.tar
```

## Criar cluster para o teste

```shell
sudo snap install microk8s --classic
sudo microk8s status --wait-ready
sudo microk8s enable ingress dns
```

## Verificar cluster de teste

```shell
sudo microk8s kubectl get nodes
sudo microk8s kubectl get services
sudo microk8s kubectl get all --all-namespaces
sudo microk8s kubectl get pods --all-namespaces
```

## Criar namespace de teste

```shell
sudo microk8s kubectl create namespace teste
```

## Armazenar arquivo tar como secret

```shell
sudo microk8s kubectl create secret generic teste-secret --from-file=teste.tar --namespace teste
sudo microk8s kubectl get secret teste-secret --namespace teste
sudo microk8s kubectl describe secret teste-secret --namespace teste
```

## Criar configmap para o nginx

### Gerar arquivo de configuração para o nginx

```shell
echo 'server {
    listen       8080;
    listen  [::]:8080;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}' > default.conf
```

### Criar configmap contendo o arquivo de configuração para o nginx

```shell
sudo microk8s kubectl create configmap teste-config --from-file=default.conf --namespace teste
```

## Criar deployment para o nginx

### Gerar o yaml de deployment para ao nginx

```shell
echo 'apiVersion: apps/v1
kind: Deployment
metadata:
  name: teste-deployment
  labels:
    app: nginx
  namespace: teste
  annotations:
    monitoring: "true"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: teste-container
        image: nginx:stable
        ports:
        - containerPort: 8080
        volumeMounts:
          - name: teste-secret
            mountPath: /usr/share/nginx/html/teste
          - name: teste-config
            mountPath: /etc/nginx/conf.d
      volumes:
        - name: teste-secret
          secret:
            secretName: teste-secret
        - name: teste-config
          configMap:
            name: teste-config
      restartPolicy: Always' > teste-deployment.yaml
```

### Criar o deploymenr

```shell
sudo microk8s kubectl create -f teste-deployment.yaml
```

### Criar serviço

```shell
sudo microk8s kubectl expose deployment teste-deployment --name=teste-service --type=NodePort --port=8080 --namespace teste
```

### Verificar serviço

```shell
sudo microk8s kubectl get service teste-service --namespace teste
```

## Criar ingress

### Gerar o yaml de ingress para o nginx

```shell
echo 'apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: teste-ingress
spec:
  rules:
    - host: teste.info
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: teste-service
                port:
                  number: 8080' > teste-ingress.yaml
```

### Criar o ingress

```shell
sudo microk8s kubectl apply -f teste-ingress.yaml --namespace teste
```

Para acessar o endereço <http://teste.info>, adicione no "/etc/hosts", por exemplo, se seu IP onde está instalado o MicroK8s for 192.168.1.100:

```shell
nano -c /etc/hosts
```

Deverá ficar como abaixo:

```txt
# Host addresses
127.0.0.1  localhost
127.0.1.1  microk8s
::1        localhost ip6-localhost ip6-loopback
ff02::1    ip6-allnodes
ff02::2    ip6-allrouters
192.168.1.100     teste.info
```

Para verificar se o download do arquivo teste.tar está correto execute:

```shell
curl http://teste.info/teste/teste.tar -o teste.tar
tar -tf teste.tar
```

Deverá listar o conteúdo do arquivo como no exemplo abaixo:

```txt
teste/
teste/B.txt
teste/A.txt
teste/C.txt
```
