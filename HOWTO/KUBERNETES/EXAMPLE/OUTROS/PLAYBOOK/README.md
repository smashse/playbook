## Criar namespace

```shell
kubectl create namespace teste
```

```shell
kubectl create ns teste
```

OU

```shell
echo 'apiVersion: v1
kind: Namespace
metadata:
  name: teste' > teste_namespace.yaml
```

```shell
kubectl apply -f teste_namespace.yaml
```

## Criar configmap

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

```shell
kubectl create configmap teste-config --from-file=default.conf --namespace=teste
```

OU

```shell
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

```shell
kubectl apply -f teste_configmap.yaml
```

## Criar deployment

```shell
kubectl create deployment teste-deployment --image=nginx:stable --port=8080 --replicas=1 --namespace=teste
```

OU

```shell
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

```shell
kubectl apply -f teste_deployment_volume.yaml
```

## Criar service

```shell
kubectl expose deployment teste-deployment --type=NodePort --port=8080 --namespace=teste
```

OU

```shell
echo 'apiVersion: v1
kind: Service
metadata:
  labels:
    app: teste-deployment
  name: teste-deployment
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

```shell
kubectl apply -f teste_service.yaml
```

## Criar ingress

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
                name: teste-deployment
                port:
                  number: 8080' > teste_ingress.yaml
```

```shell
kubectl apply -f teste_ingress.yaml --namespace=teste
```
