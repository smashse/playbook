## Install Multipass

```bash
sudo snap install multipass --classic
```

# MicroK8s

MicroK8s is the smallest, fastest, fully-conformant Kubernetes that tracks upstream releases and makes clustering trivial. MicroK8s is great for offline development, prototyping, and testing.

## Create a MicroK8s template

```bash
echo '#cloud-config
runcmd:
 - apt update --fix-missing
 - snap refresh
 - snap install microk8s --classic
 - microk8s status --wait-ready
 - microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

## Create a MicroK8s instance

```bash
multipass launch focal -n microk8s -c 2 -m 2G -d 10G --cloud-init cloud-config-microk8s.yaml
```

## Export the current MicroK8s configuration for use with Kubectl

### Create the folder to store the configuration of the Kubernetes cluster in the test instance

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Export the MicroK8s configuration in the test instance to the created folder

```bash
multipass exec microk8s sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

### Use in your session the configuration exported as default for use with Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

### Install Kubectl

```bash
sudo snap install kubectl --classic
```

```bash
kubectl get no
```

```txt
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   1m    v1.21.3-3+90fd5f3d2aea0a
```

### Add an IP alias of the test instance to teste.info

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.info/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     teste.info/' | sudo tee -a /etc/hosts
```

### Deploy a test application

```bash
kubectl apply -f https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/KUBERNETES/COMBO/example_combo_full.yaml
```

# Grafana

## Create a Grafana template

```bash
echo '#cloud-config
runcmd:
 - echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
 - wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
 - cho "DEBIAN_FRONTEND=noninteractive" >> /etc/environment
 - source /etc/environment && source /etc/environment
 - apt update --fix-missing
 - apt -y install grafana
 - systemctl daemon-reload
 - systemctl start grafana-server
 - systemctl status grafana-server
 - systemctl enable grafana-server.service' > cloud-config-grafana.yaml
```

## Create a Grafana instance

```bash
multipass launch focal -n grafana -c 2 -m 1G -d 10G --cloud-init cloud-config-grafana.yaml
```

### Add an IP alias of the test instance to grafana.info

```bash
multipass info grafana | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     grafana.info/' | sudo tee -a /etc/hosts
```

# Prometheus

## Create a Prometheus template

```bash
echo '#cloud-config
runcmd:
 - echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
 - wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
 - cho "DEBIAN_FRONTEND=noninteractive" >> /etc/environment
 - source /etc/environment && source /etc/environment
 - apt update --fix-missing
 - apt -y install prometheus
 - systemctl daemon-reload
 - systemctl start prometheus-server
 - systemctl status prometheus-server
 - systemctl enable prometheus-server.service' > cloud-config-prometheus.yaml
```

## Create a Prometheus instance

```bash
multipass launch focal -n prometheus -c 2 -m 1G -d 10G --cloud-init cloud-config-prometheus.yaml
```

### Add an IP alias of the test instance to prometheus.info

```bash
multipass info prometheus | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     prometheus.info/' | sudo tee -a /etc/hosts
```

# Deploy the Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

OR

```bash
wget -c https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```bash
sed -i '/- --secure-port=443/a\        - --kubelet-insecure-tls' components.yaml
```

```bash
kubectl apply -f components.yaml
```

```bash
kubectl get deployment metrics-server -n kube-system
```

# Deploy the Kube-State-Metrics

```bash
kubectl apply -f https://github.com/kubernetes/kube-state-metrics/tree/master/examples/standard --recursive
```

OR

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-state-metrics prometheus-community/kube-state-metrics --namespace monitoring --create-namespace
```

# Istio + Basic Prometheus

Istio provides a basic sample installation to quickly get Prometheus up and running:

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/addons/prometheus.yaml
```

```bash
echo 'apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: istio-system
spec:
  rules:
  - host: prometheus.istio.info
    http:
      paths:
      - backend:
          service:
            name: prometheus
            port:
              number: 9090
        path: /
        pathType: Prefix' > prometheus_ingress.yaml
```

```bash
kubectl apply -f prometheus_ingress.yaml
```

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     prometheus.istio.info/' | sudo tee -a /etc/hosts
```

# Create test deployments

```bash
echo 'africa
america
asia
europa
oceania' > lista
```

```bash
wget -c https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/KUBERNETES/COMBO/example_combo_full.yaml
```

```bash
for i in `cat lista.txt` ; do sed "s/teste/$i/" example_combo_full.yaml > app-$i.yaml ; kubectl apply -f app-$i.yaml ; done
```

```bash
for i in `cat lista.txt` ; do multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed "s/$/     $i.info/" | sudo tee -a /etc/hosts ; done
```

Sources:

https://istio.io/latest/docs/ops/integrations/prometheus/

https://github.com/kubernetes-sigs/metrics-server

https://github.com/kubernetes/kube-state-metrics

https://github.com/helm/charts/tree/master/stable/prometheus-operator/templates/grafana/dashboards-1.14

https://grafana.com/grafana/dashboards/10000
