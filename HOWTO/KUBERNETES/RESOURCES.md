# Recursos adicionais

## Instalar Krew

**Krew é o gerenciador de plug-ins para a kubectl.**

<https://github.com/kubernetes-sigs/krew>

```bash
(
  set -x; cd "$(mktemp -d)" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/' -e 's/aarch64$/arm64/')" &&
  "$KREW" install krew
)
```

```bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

## Instalar o Neat

**Neat torna os manifestos do Kubernetes muito mais legíveis ao remover a desordem.**

<https://github.com/itaysk/kubectl-neat>

```bash
kubectl krew install neat
```

## Criar namespace

```bash
kubectl create namespace teste
```

```bash
kubectl create ns teste
```

OU

```bash
echo 'apiVersion: v1
kind: Namespace
metadata:
  name: teste' > teste_namespace.yaml
```

```bash
kubectl apply -f teste_namespace.yaml
```

### Exibir o yaml do namespace

```bash
kubectl get namespace teste -o yaml
```

### Exportar o yaml do namespace

**_BRUTO_**

```bash
kubectl get namespace teste -o yaml > teste_namespace.yaml
```

**_LIMPO_**

```bash
kubectl get namespace teste -o yaml | kubectl neat > teste_namespace.yaml
```

## Criar configmap

```bash
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

```bash
kubectl create configmap teste-config --from-file=default.conf --namespace=teste
```

OU

```bash
echo 'apiVersion: v1
data:
  default.conf: |
    server {
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
    }
kind: ConfigMap
metadata:
  name: teste-config
  namespace: teste' > teste_configmap.yaml
```

```bash
kubectl apply -f teste_configmap.yaml
```

### Exibir o yaml do configmap

```bash
kubectl get configmap teste-config --namespace=teste -o yaml
```

### Exportar o yaml do configmap

**_BRUTO_**

```bash
kubectl get configmap teste-config --namespace=teste -o yaml > teste_configmap.yaml
```

**_LIMPO_**

```bash
kubectl get configmap teste-config --namespace=teste -o yaml | kubectl neat > teste_configmap.yaml
```

## Criar deployment

```bash
kubectl create deployment teste-deployment --image=nginx:stable --port=8080 --replicas=1 --namespace=teste
```

OU

```bash
echo 'apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: teste-deployment
  name: teste-deployment
  namespace: teste
spec:
  replicas: 1
  selector:
    matchLabels:
      app: teste-deployment
  template:
    metadata:
      labels:
        app: teste-deployment
    spec:
      containers:
      - image: nginx:stable
        name: nginx
        ports:
        - containerPort: 8080
        volumeMounts:
          - name: teste-config
            mountPath: /etc/nginx/conf.d
      volumes:
        - name: teste-config
          configMap:
            name: teste-config
      dnsPolicy: ClusterFirst' > teste_deployment_volume.yaml
```

```bash
kubectl apply -f teste_deployment_volume.yaml
```

### Exibir o yaml do deployment

```bash
kubectl get deployment teste-deployment --namespace=teste -o yaml
```

### Exportar o yaml do deployment

**_BRUTO_**

```bash
kubectl get deployment teste-deployment --namespace=teste -o yaml > teste_deployment_volume.yaml
```

**_LIMPO_**

```bash
kubectl get deployment teste-deployment --namespace=teste -o yaml | kubectl neat > teste_deployment_volume.yaml
```

## Criar service

```bash
kubectl expose deployment teste-deployment --name=teste-service --type=NodePort --port=8080 --namespace=teste
```

OU

```bash
echo 'apiVersion: v1
kind: Service
metadata:
  labels:
    app: teste-deployment
  name: teste-service
  namespace: teste
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: teste-deployment
  type: NodePort
status:
  loadBalancer: {}' > teste_service.yaml
```

```bash
kubectl apply -f teste_service.yaml
```

### Exibir yaml do service

```bash
kubectl get service teste-service --namespace=teste -o yaml
```

### Exportar yaml do service

**_BRUTO_**

```bash
kubectl get service teste-service --namespace=teste -o yaml > teste_service.yaml
```

**_LIMPO_**

```bash
kubectl get service teste-service --namespace=teste -o yaml | kubectl neat > teste_service.yaml
```

## Criar ingress

```bash
kubectl create ingress teste-ingress --namespace teste --rule="teste.info/*=teste-service:8080"
```

OU

```bash
echo 'apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: teste-ingress
  namespace: teste
spec:
  rules:
  - host: teste.info
    http:
      paths:
      - backend:
          service:
            name: teste-service
            port:
              number: 8080
        path: /
        pathType: Prefix' > teste_ingress.yaml
```

```bash
kubectl apply -f teste_ingress.yaml --namespace=teste
```

### Exibir yaml do ingress

```bash
kubectl get ingress teste-ingress --namespace=teste -o yaml
```

### Exportar yaml do ingress

**_BRUTO_**

```bash
kubectl get ingress teste-ingress --namespace=teste -o yaml > teste_ingress.yaml
```

**_LIMPO_**

```bash
kubectl get ingress teste-ingress --namespace=teste -o yaml | kubectl neat > teste_ingress.yaml
```

# COMBO

```bash
echo 'apiVersion: v1
items:
- apiVersion: v1
  kind: Namespace
  metadata:
    name: teste
- apiVersion: v1
  data:
    default.conf: |
      server {
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
      }
  kind: ConfigMap
  metadata:
    name: teste-config
    namespace: teste
- apiVersion: apps/v1
  kind: Deployment
  metadata:
    labels:
      app: teste-deployment
    name: teste-deployment
    namespace: teste
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: teste-deployment
    strategy:
      rollingUpdate:
        maxSurge: 25%
        maxUnavailable: 25%
      type: RollingUpdate
    template:
      metadata:
        labels:
          app: teste-deployment
      spec:
        containers:
        - image: nginx:stable
          name: teste-pod
          ports:
          - containerPort: 8080
            protocol: TCP
          volumeMounts:
          - mountPath: /etc/nginx/conf.d
            name: teste-config
        dnsPolicy: ClusterFirst
        volumes:
        - configMap:
            name: teste-config
          name: teste-config
- apiVersion: v1
  kind: Service
  metadata:
    labels:
      app: teste-deployment
    name: teste-service
    namespace: teste
  spec:
    ports:
    - port: 8080
    selector:
      app: teste-deployment
    type: NodePort
- apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: teste-ingress
    namespace: teste
  spec:
    rules:
    - host: teste.info
      http:
        paths:
        - backend:
            service:
              name: teste-service
              port:
                number: 8080
          path: /
          pathType: Prefix
kind: List
metadata: {}' > teste_combo.yaml
```

```bash
kubectl apply -f teste_combo.yaml
```
