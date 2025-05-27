*Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)*

# Requisitos para esta POC

Esta POC usará o Multipass para criar instâncias para instalar o Grafana, Prometheus e Microk8s, instalaremos o Metrics Server, Kube-State-Metrics e Istio + Prometheus Básico e então faremos as métricas usadas por nossa instância principal com o Prometheus.

## Instale o Multipass

```bash
sudo snap install multipass --classic
```

# MicroK8s

MicroK8s é o Kubernetes menor, mais rápido e totalmente compatível que acompanha as versões upstream e torna o clustering trivial. O MicroK8s é ótimo para desenvolvimento offline, prototipagem e testes.

## Crie um template MicroK8s

```bash
echo '#cloud-config
runcmd:
 - apt update --fix-missing
 - snap refresh
 - snap install microk8s --classic
 - microk8s status --wait-ready
 - microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

## Crie uma instância MicroK8s

```bash
multipass launch focal -n microk8s -c 2 -m 2G -d 10G --cloud-init cloud-config-microk8s.yaml
```

## Exporte a configuração atual do MicroK8s para uso com o Kubectl

### Crie a pasta para armazenar a configuração do cluster Kubernetes na instância de teste

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Exporte a configuração do MicroK8s na instância de teste para a pasta criada

```bash
multipass exec microk8s sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

### Use em sua sessão a configuração exportada como padrão para uso com o Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

### Instale o Kubectl

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

### Adicione um alias de IP da instância de teste para teste.info

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.info/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     teste.info/' | sudo tee -a /etc/hosts
```

### Implante uma aplicação de teste

```bash
kubectl apply -f https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/KUBERNETES/COMBO/example_combo_full.yaml
```

# Grafana

## Crie um template Grafana

```bash
echo '#cloud-config
runcmd:
 - echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
 - wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
 - echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment
 - source /etc/environment && source /etc/environment
 - apt update --fix-missing
 - apt -y install grafana
 - systemctl daemon-reload
 - systemctl start grafana-server
 - systemctl status grafana-server
 - systemctl enable grafana-server.service' > cloud-config-grafana.yaml
```

## Crie uma instância Grafana

```bash
multipass launch focal -n grafana -c 2 -m 1G -d 10G --cloud-init cloud-config-grafana.yaml
```

### Adicione um alias de IP da instância de teste para grafana.info

```bash
multipass info grafana | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     grafana.info/' | sudo tee -a /etc/hosts
```

### Adicione uma Fonte de Dados

Para adicionar a Fonte de Dados ao Prometheus com a URL "http://prometheus.info:9090", basta seguir os passos conforme a documentação abaixo:

https://grafana.com/docs/grafana/latest/datasources/add-a-data-source/

# Prometheus

## Crie um template Prometheus

```bash
echo '#cloud-config
runcmd:
 - echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
 - wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
 - echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment
 - source /etc/environment && source /etc/environment
 - apt update --fix-missing
 - apt -y install prometheus
 - systemctl daemon-reload
 - systemctl start prometheus
 - systemctl status prometheus
 - systemctl enable prometheus.service' > cloud-config-prometheus.yaml
```

## Crie uma instância Prometheus

```bash
multipass launch focal -n prometheus -c 2 -m 1G -d 10G --cloud-init cloud-config-prometheus.yaml
```

### Adicione um alias de IP da instância de teste para prometheus.info

```bash
multipass info prometheus | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     prometheus.info/' | sudo tee -a /etc/hosts
```

# Implante o Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

OU

```bash
wget -c https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```bash
sed -i '/- --secure-port=443/a\        - --kubelet-insecure-tls' components.yaml
```

```bash
kubectl apply -f components.yaml
```

OU

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm install metrics-server metrics-server/metrics-server --set 'args={--kubelet-insecure-tls}' --namespace kube-system --create-namespace
```

```bash
kubectl get deployment metrics-server -n kube-system
```

# Implante o Kube-State-Metrics

```bash
kubectl apply -f https://github.com/kubernetes/kube-state-metrics/tree/master/examples/standard --recursive
```

OU

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-state-metrics prometheus-community/kube-state-metrics --namespace monitoring --create-namespace
```

```bash
kubectl get deployment kube-state-metrics -n monitoring
```

# Istio + Prometheus Básico

Istio fornece uma instalação de exemplo básica para colocar o Prometheus rapidamente em funcionamento:

```bash
kubectl create ns istio-system
```

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

## Permita que um servidor Prometheus (prometheus.info) colete séries temporais selecionadas do servidor Prometheus em execução no Microk8s (prometheus.istio.info).

### Acesse a instância do Prometheus

```bash
multipass exec prometheus bash
```

### Configurando a federação

```bash
sudo tee -a /etc/prometheus/prometheus.yml <<EOF
  - job_name: 'federate'
    scrape_interval: 15s

    honor_labels: true
    metrics_path: '/federate'

    params:
      'match[]':
        - '{job="prometheus"}'
        - '{__name__=~"job:.*"}'

    static_configs:
      - targets:
        - 'prometheus.istio.info'
EOF
```

### Reinicie o Prometheus

```bash
sudo systemctl restart prometheus
```

# Crie implantações de teste

```bash
echo 'africa
america
asia
europa
oceania' > lista.txt
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

**Fontes:**

https://istio.io/latest/docs/ops/integrations/prometheus/

https://github.com/kubernetes-sigs/metrics-server

https://github.com/kubernetes/kube-state-metrics

https://github.com/helm/charts/tree/master/stable/prometheus-operator/templates/grafana/dashboards-1.14

https://prometheus.io/docs/prometheus/latest/federation/

https://grafana.com/grafana/dashboards/10000

https://grafana.com/grafana/dashboards/10856

https://grafana.com/grafana/dashboards/10858

https://grafana.com/grafana/dashboards/8588
