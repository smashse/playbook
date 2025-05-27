*Read this in other languages: [en-US](RESOURCES.md), [pt-BR](RESOURCES.pt-BR.md)*

# Additional Resources

## Install Krew

**Krew is the plugin manager for kubectl.**

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

## Install Neat

**Neat makes Kubernetes manifests much more readable by removing clutter.**

<https://github.com/itaysk/kubectl-neat>

```bash
kubectl krew install neat
```

## Create namespace

```bash
kubectl create namespace test
```

```bash
kubectl create ns test
```

OR

```bash
echo 'apiVersion: v1
kind: Namespace
metadata:
  name: test' > test_namespace.yaml
```

```bash
kubectl apply -f test_namespace.yaml
```

### Display namespace yaml

```bash
kubectl get namespace test -o yaml
```

### Export namespace yaml

**_RAW_**

```bash
kubectl get namespace test -o yaml > test_namespace.yaml
```

**_CLEAN_**

```bash
kubectl get namespace test -o yaml | kubectl neat > test_namespace.yaml
```

## Create configmap

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
kubectl create configmap test-config --from-file=default.conf --namespace=test
```

OR

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
  name: test-config
  namespace: test' > test_configmap.yaml
```

```bash
kubectl apply -f test_configmap.yaml
```

### Display configmap yaml

```bash
kubectl get configmap test-config --namespace=test -o yaml
```

### Export configmap yaml

**_RAW_**

```bash
kubectl get configmap test-config --namespace=test -o yaml > test_configmap.yaml
```

**_CLEAN_**

```bash
kubectl get configmap test-config --namespace=test -o yaml | kubectl neat > test_configmap.yaml
```

## Create deployment

```bash
kubectl create deployment test-deployment --image=nginx:stable --port=8080 --replicas=1 --namespace=test
```

OR

```bash
echo 'apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: test-deployment
  name: test-deployment
  namespace: test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-deployment
  template:
    metadata:
      labels:
        app: test-deployment
    spec:
      containers:
      - image: nginx:stable
        name: nginx
        ports:
        - containerPort: 8080
        volumeMounts:
          - name: test-config
            mountPath: /etc/nginx/conf.d
      volumes:
        - name: test-config
          configMap:
            name: test-config
      dnsPolicy: ClusterFirst' > test_deployment_volume.yaml
```

```bash
kubectl apply -f test_deployment_volume.yaml
```

### Display deployment yaml

```bash
kubectl get deployment test-deployment --namespace=test -o yaml
```

### Export deployment yaml

**_RAW_**

```bash
kubectl get deployment test-deployment --namespace=test -o yaml > test_deployment_volume.yaml
```

**_CLEAN_**

```bash
kubectl get deployment test-deployment --namespace=test -o yaml | kubectl neat > test_deployment_volume.yaml
```

## Create service

```bash
kubectl expose deployment test-deployment --name=test-service --type=NodePort --port=8080 --namespace=test
```

OR

```bash
echo 'apiVersion: v1
kind: Service
metadata:
  labels:
    app: test-deployment
  name: test-service
  namespace: test
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: test-deployment
  type: NodePort
status:
  loadBalancer: {}' > test_service.yaml
```

```bash
kubectl apply -f test_service.yaml
```

### Display service yaml

```bash
kubectl get service test-service --namespace=test -o yaml
```

### Export service yaml

**_RAW_**

```bash
kubectl get service test-service --namespace=test -o yaml > test_service.yaml
```

**_CLEAN_**

```bash
kubectl get service test-service --namespace=test -o yaml | kubectl neat > test_service.yaml
```

## Create ingress

```bash
kubectl create ingress test-ingress --namespace test --rule="test.info/*=test-service:8080"
```

OR

```bash
echo 'apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: test
spec:
  rules:
  - host: test.info
    http:
      paths:
      - backend:
          service:
            name: test-service
            port:
              number: 8080
        path: /
        pathType: Prefix' > test_ingress.yaml
```

```bash
kubectl apply -f test_ingress.yaml --namespace=test
```

### Display ingress yaml

```bash
kubectl get ingress test-ingress --namespace=test -o yaml
```

### Export ingress yaml

**_RAW_**

```bash
kubectl get ingress test-ingress --namespace=test -o yaml > test_ingress.yaml
```

**_CLEAN_**

```bash
kubectl get ingress test-ingress --namespace=test -o yaml | kubectl neat > test_ingress.yaml
```

# COMBO

```bash
echo 'apiVersion: v1
items:
- apiVersion: v1
  kind: Namespace
  metadata:
    name: test
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
    name: test-config
    namespace: test
- apiVersion: apps/v1
  kind: Deployment
  metadata:
    labels:
      app: test-deployment
    name: test-deployment
    namespace: test
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: test-deployment
    strategy:
      rollingUpdate:
        maxSurge: 25%
        maxUnavailable: 25%
      type: RollingUpdate
    template:
      metadata:
        labels:
          app: test-deployment
      spec:
        containers:
        - image: nginx:stable
          name: test-pod
          ports:
          - containerPort: 8080
            protocol: TCP
          volumeMounts:
          - mountPath: /etc/nginx/conf.d
            name: test-config
        dnsPolicy: ClusterFirst
        volumes:
        - configMap:
            name: test-config
          name: test-config
- apiVersion: v1
  kind: Service
  metadata:
    labels:
      app: test-deployment
    name: test-service
    namespace: test
  spec:
    ports:
    - port: 8080
    selector:
      app: test-deployment
    type: NodePort
- apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: test-ingress
    namespace: test
  spec:
    rules:
    - host: test.info
      http:
        paths:
        - backend:
            service:
              name: test-service
              port:
                number: 8080
          path: /
          pathType: Prefix
kind: List
metadata: {}' > test_combo.yaml
```

```bash
kubectl apply -f test_combo.yaml
```
