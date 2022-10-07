# Botkube + Grafana, Prometheus and Alertmanager

This POC aims to demonstrate an environment where Kubernetes alerts, separated by namespaces, will be forwarded to multiple channels using Botkube.

## Microk8s

```bash
echo '#cloud-config
runcmd:
 - apt update --fix-missing
 - snap refresh
 - snap install microk8s --classic
 - microk8s status --wait-ready
 - microk8s enable dns ingress metrics-server prometheus' > cloud-config-microk8s.yaml
 ```

```bash
multipass launch jammy -n microk8s -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
```

```bash
sudo mkdir -p $HOME/.kube/configs
```

```bash
multipass exec microk8s sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

```bash
chmod 0600 $KUBECONFIG
```

### Create Ingress for access to Grafana, Prometheus and Alertmanager

```bash
kubectl wait deploy/kube-prom-stack-grafana --namespace=observability --for condition=Available=True --timeout=90s
kubectl create ingress grafana --namespace=observability --rule="grafana.multipass/*=kube-prom-stack-grafana:80" --class=public
kubectl wait deploy/kube-prom-stack-kube-prome-operator --namespace=observability --for condition=Available=True --timeout=90s
kubectl create ingress prometheus --namespace=observability --rule="prometheus.multipass/*=kube-prom-stack-kube-prome-prometheus:9090" --class=public
kubectl create ingress alertmanager --namespace=observability --rule="alertmanager.multipass/*=kube-prom-stack-kube-prome-alertmanager:9093" --class=public
```

### Add an IP alias for Grafana, Prometheus and Alertmanager

```bash
echo "# Microk8s" | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.multipass/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     grafana.multipass/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     prometheus.multipass/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     alertmanager.multipass/' | sudo tee -a /etc/hosts
```

**Note:** The default User is "admin" and Password is "prom-operator", change after first access.

URL's to access Grafana, Prometheus and Alertmanager:

**Grafana:** <http://grafana.multipass>

**Prometheus:** <http://prometheus.multipass>

**Alertmanager:** <http://alertmanager.multipass>

## Kubenav

```bash
helm repo add kubenav https://kubenav.github.io/helm-repository
helm repo update
```

```bash
helm install kubenav kubenav/kubenav \
--namespace kubenav \
--create-namespace
```

### Create Ingress for access to Kubenav

```bash
kubectl wait deploy/kubenav --namespace=kubenav --for condition=Available=True --timeout=90s
kubectl create ingress kubenav --namespace=kubenav --rule="kubenav.multipass/*=kubenav:14122" --class=public
```

### Add an IP alias for Kubenav

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     kubenav.multipass/' | sudo tee -a /etc/hosts
```

## BotKube

### Install BotKube to the Slack workspace using the following instructions to the channel "devops-notifications"

<https://www.botkube.io/installation/slack/#install-botkube-to-the-slack-workspace>

<https://www.botkube.io/installation/slack/>

### Change the "channel" and "token" values to the one provided after enabling the BotKube app in Slack

```bash
export CLUSTER_NAME={cluster_name}
export ALLOW_KUBECTL={allow_kubectl}
export SLACK_CHANNEL_NAME={channel_name}
export SLACK_API_BOT_TOKEN="{token}"
```

```bash
echo "communications:
  default-group:
    slack:
      enabled: true
      token: ${SLACK_API_BOT_TOKEN}
      channels:
        default:
          name: ${SLACK_CHANNEL_NAME}
executors:
  kubectl-read-only:
    kubectl:
      enabled: ${ALLOW_KUBECTL}
settings:
  clusterName: ${CLUSTER_NAME}" > botkube_values.yaml
```

```bash
helm repo add botkube https://charts.botkube.io
helm repo update
```

```bash
helm install botkube botkube/botkube \
--namespace botkube \
--create-namespace \
--values ./botkube_values.yaml
```

OR

```bash
echo "teste
producao" > list_ns.txt &&
for i in `cat list_ns.txt` ; do export NS_LIST=$i && echo "communications:
  default-group:
    slack:
      channels:
        ${NS_LIST}:
          name: ${NS_LIST}-alerts
          bindings:
            executors:
              - kubectl-read-only-${NS_LIST}
            sources:
              - k8s-events-${NS_LIST}
executors:
  kubectl-read-only-${NS_LIST}:
    kubectl:
      enabled: true
      namespaces:
        exclude: []
        include:
          - ${NS_LIST}
      commands:
        verbs:
          - api-resources
          - api-versions
          - auth
          - cluster-info
          - describe
          - diff
          - explain
          - get
          - logs
          - top
        resources:
          - configmaps
          - daemonsets
          - deployments
          - ingress
          - namespaces
          - pods
          - services
          - statefulsets
          - storageclasses
      defaultNamespace: ${NS_LIST}
      restrictAccess: false
sources:
  "k8s-events-${NS_LIST}":
    kubernetes:
      namespaces:
        include:
          - ${NS_LIST}
      resources:
        - name: v1/pods
          events:
            # - create
            # - delete
            - error
        - name: v1/services
          events:
            # - create
            # - delete
            - error
        - name: apps/v1/deployments
          events:
            # - create
            # - update
            # - delete
            - error
          updateSetting:
            includeDiff: true
            fields:
              - spec.template.spec.containers[*].image
              - status.availableReplicas
        - name: apps/v1/statefulsets
          events:
            # - create
            # - update
            # - delete
            - error
          updateSetting:
            includeDiff: true
            fields:
              - spec.template.spec.containers[*].image
              - status.readyReplicas
        - name: networking.k8s.io/v1/ingresses
          events:
            # - create
            # - delete
            - error
        - name: v1/nodes
          events:
            # - create
            # - delete
            - error
        - name: v1/namespaces
          events:
            # - create
            # - delete
            - error
        - name: v1/persistentvolumes
          events:
            # - create
            # - delete
            - error
        - name: v1/persistentvolumeclaims
          events:
            # - create
            # - delete
            - error
        - name: v1/configmaps
          events:
            # - create
            # - delete
            - error
        - name: apps/v1/daemonsets
          events:
            # - create
            # - update
            # - delete
            - error
          updateSetting:
            includeDiff: true
            fields:
              - spec.template.spec.containers[*].image
              - status.numberReady
        - name: batch/v1/jobs
          events:
            # - create
            # - update
            # - delete
            - error
          updateSetting:
            includeDiff: true
            fields:
              - spec.template.spec.containers[*].image
              - status.conditions[*].type
        - name: rbac.authorization.k8s.io/v1/roles
          events:
            # - create
            # - delete
            - error
        - name: rbac.authorization.k8s.io/v1/rolebindings
          events:
            # - create
            # - delete
            - error
        - name: rbac.authorization.k8s.io/v1/clusterrolebindings
          events:
            # - create
            # - delete
            - error
        - name: rbac.authorization.k8s.io/v1/clusterroles
          events:
            # - create
            # - delete
            - error" > botkube_values_ns_${NS_LIST}.yaml ; done
```

```bash
helm install botkube botkube/botkube \
--namespace botkube \
--create-namespace \
--values ./botkube_values.yaml \
--values ./botkube_values_ns_teste.yaml,./botkube_values_ns_producao.yaml
```

```bash
echo "teste
producao" > list_ns.txt &&
for i in `cat list_ns.txt` ; do export NS_LIST=$i && echo "apiVersion: v1
items:
- apiVersion: v1
  kind: Namespace
  metadata:
    name: ${NS_LIST}
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
    name: ${NS_LIST}-config
    namespace: ${NS_LIST}
- apiVersion: apps/v1
  kind: Deployment
  metadata:
    labels:
      app: ${NS_LIST}-deployment
    name: ${NS_LIST}-deployment
    namespace: ${NS_LIST}
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: ${NS_LIST}-deployment
    strategy:
      rollingUpdate:
        maxSurge: 25%
        maxUnavailable: 25%
      type: RollingUpdate
    template:
      metadata:
        labels:
          app: ${NS_LIST}-deployment
      spec:
        containers:
        - image: nginx:stable
          name: ${NS_LIST}-pod
          ports:
          - containerPort: 8080
            protocol: TCP
          volumeMounts:
          - mountPath: /etc/nginx/conf.d
            name: ${NS_LIST}-config
        dnsPolicy: ClusterFirst
        volumes:
        - configMap:
            name: ${NS_LIST}-config
          name: ${NS_LIST}-config
- apiVersion: v1
  kind: Service
  metadata:
    labels:
      app: ${NS_LIST}-deployment
    name: ${NS_LIST}-service
    namespace: ${NS_LIST}
  spec:
    ports:
    - port: 8080
    selector:
      app: ${NS_LIST}-deployment
    type: NodePort
- apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: ${NS_LIST}-ingress
    namespace: ${NS_LIST}
  spec:
    rules:
    - host: ${NS_LIST}.multipass
      http:
        paths:
        - backend:
            service:
              name: ${NS_LIST}-service
              port:
                number: 8080
          path: /
          pathType: Prefix
kind: List
metadata: {}" > ${NS_LIST}_combo.yaml ; done
```

```bash
for i in `cat list_ns.txt` ; do kubectl apply -f $i"_combo.yaml" ; done
```

### Get a list of namespaces

```bash
kubectl get ns -o json | jq '.items[].metadata.name' | tr -d '"'
```

## Slack

```bash
@BotKube ping
@BotKube commands list
@BotKube get no --cluster-name microk8s
@BotKube get deployments --all-namespaces --cluster-name microk8s
```

**Sources:**

<https://multipass.run/>

<https://microk8s.io/>

<https://grafana.com/>

<https://prometheus.io/>

<https://github.com/prometheus-community/helm-charts>

<https://www.botkube.io/>

<https://github.com/samber/awesome-prometheus-alerts>
