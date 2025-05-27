*Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)*

# Grafana + Prometheus + Alertmanager + Slack

Esta POC tem como objetivo apresentar o processo de integração do Slack com um webhook para receber alertas do Alertmanager.

Foi implementado com Multipass, Microk8s, Kubernetes, Helm e Kube-Prometheus-Stack.

**Observação:** Instruções sobre como instalar o Multipass para [Linux](https://github.com/smashse/playbook/blob/master/HOWTO/ENV/LINUXENV.md#install-multipass) e [Mac](https://github.com/smashse/playbook/blob/master/HOWTO/ENV/MACENV.md#install-multipass).

## Microk8s

```bash
echo '#cloud-config
runcmd:
 - apt update --fix-missing
 - snap refresh
 - snap install microk8s --classic
 - microk8s status --wait-ready
 - microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

```bash
multipass launch focal -n microk8s -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
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

### Implante o Metrics Server

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm install metrics-server metrics-server/metrics-server \
--set 'args={--kubelet-insecure-tls}' \
--namespace kube-system \
--create-namespace
```

```bash
kubectl wait deploy/metrics-server --namespace=kube-system --for condition=Available=True --timeout=90s
```

<!-- ### Implante o Kube-State-Metrics

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-state-metrics prometheus-community/kube-state-metrics \
--namespace monitoring \
--create-namespace
```

```bash
kubectl wait deploy/kube-state-metrics --namespace=monitoring --for condition=Available=True --timeout=90s
``` -->

### Implante o Prometheus

```bash
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

<!-- #### Prometheus

```bash
helm install prometheus prometheus-community/prometheus \
--set alertmanager.persistentVolume.storageClass="default",server.persistentVolume.storageClass="default" \
--namespace prometheus \
--create-namespace
```

```bash
kubectl get pods -n prometheus
``` -->

#### Prometheus Operator

##### Crie um App Slack para Incoming Webhook que aponte para o canal "prometheus-notifications"

<https://api.slack.com/apps?new_app=1>

<https://api.slack.com/messaging/webhooks>

Guia gráfico sobre como fazer isso, [clique aqui](./images/prometheus/README.md).

##### Valores do Slack

Valores do Prometheus:

```bash
nano -c prometheus_values.yaml
```

```yaml
---
kubelet:
  enabled: true
  serviceMonitor:
    https: false
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeEtcd:
  enabled: false
kubeProxy:
  enabled: false
prometheus:
  prometheusSpec:
    externalUrl: http://prometheus.multipass
```

Ou baixe como abaixo:

```bash
wget -c https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/PROMETHEUS/values/prometheus_values.yaml
```

Valores do Alertmanager:

```bash
nano -c alertmanager_values.yaml
```

Modifique o "webhook_url" em "alertmanager_values.yaml".

```yaml
---
alertmanager:
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ["..."]
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: "null"
      routes:
        # - match:
        #     alertname: Watchdog
        #   receiver: "null"
        #   continue: true
        # - match:
        #     severity: warning
        #   receiver: "MySlackChannel"
        #   continue: true
        # - match:
        #     severity: critical
        #   receiver: "MySlackChannel"
        #   continue: true
        - match_re:
            severity: "^(info|warning|critical)$"
          receiver: "MySlackChannel"
          continue: true
    receivers:
      - name: "null"
      - name: "MySlackChannel"
        slack_configs:
          - api_url: "webhook_url"
            channel: "#prometheus-notifications"
            send_resolved: true
    templates:
      - /etc/alertmanager/config/*.tmpl
  alertmanagerSpec:
    externalUrl: http://alertmanager.multipass
```

Ou baixe como abaixo:

```bash
wget -c https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/PROMETHEUS/values/alertmanager_values.yaml
```

Regras do Alertmanager:

```bash
nano -c alertmanager_rules.yaml
```

Este é um exemplo, para uma lista maior de regras que monitoram o cluster, acesse a pasta [values](./values/alertmanager_rules.yaml).

```yaml
---
additionalPrometheusRulesMap:
  custom-rules:
    groups:
      - name: RULES
        rules:
          - alert: InstanceLowMemory
            expr: :node_memory_MemAvailable_bytes:sum < 50668858390
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: “Instance {{ $labels.host }} memory low”
              description: “{{ $labels.host }} has less than 50G memory available”
          - alert: InstanceDown
            expr: up == 0
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: “Instance [{{ $labels.instance }}] down”
              description: “[{{ $labels.instance }}] of job [{{ $labels.job }}] has been down for more than 1 minute.”
```

Ou baixe como abaixo:

```bash
wget -c https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/PROMETHEUS/values/alertmanager_rules.yaml
```

##### Instale o Kube-Prometheus-Stack

```bash
helm install prometheus-operator prometheus-community/kube-prometheus-stack \
--set alertmanager.persistentVolume.storageClass="default",server.persistentVolume.storageClass="default" \
--namespace prometheus \
--create-namespace \
--values ./prometheus_values.yaml \
--values ./alertmanager_values.yaml \
--values ./alertmanager_rules.yaml
```

```bash
kubectl get pods -n prometheus
```

##### Crie Ingress para acesso ao Grafana, Prometheus e Alertmanager

```bash
kubectl wait deploy/prometheus-operator-grafana --namespace=prometheus --for condition=Available=True --timeout=90s
kubectl create ingress grafana --namespace=prometheus --rule="grafana.multipass/*=prometheus-operator-grafana:80" --class=public
kubectl wait deploy/prometheus-operator-kube-p-operator --namespace=prometheus --for condition=Available=True --timeout=90s
kubectl create ingress prometheus --namespace=prometheus --rule="prometheus.multipass/*=prometheus-operator-kube-p-prometheus:9090" --class=public
kubectl create ingress alertmanager --namespace=prometheus --rule="alertmanager.multipass/*=prometheus-operator-kube-p-alertmanager:9093" --class=public
```

##### Adicione um alias de IP para Grafana, Prometheus e Alertmanager

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.multipass/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     grafana.multipass/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     prometheus.multipass/' | sudo tee -a /etc/hosts
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     alertmanager.multipass/' | sudo tee -a /etc/hosts
```

**Observação:** O usuário padrão é "admin" e a senha é "prom-operator", altere após o primeiro acesso.

URLs para acessar Grafana, Prometheus e Alertmanager:

**Grafana:** <http://grafana.multipass>

**Prometheus:** <http://prometheus.multipass>

**Alertmanager:** <http://alertmanager.multipass>

## BotKube (Opcional)

### Instale o BotKube no workspace do Slack usando as seguintes instruções para o canal "devops-notifications"

<https://www.botkube.io/installation/slack/#install-botkube-to-the-slack-workspace>

<https://www.botkube.io/installation/slack/>

### Altere os valores "channel" e "token" para os fornecidos após habilitar o aplicativo BotKube no Slack

Guia gráfico sobre como fazer isso, [clique aqui](./images/botkube/README.md).

Modifique "your_token" em "botkube_values.yaml".

```bash
echo '
communications:
  slack:
    enabled: true
    channel: "devops-notifications"
    token: "your_token"
config:
  settings:
    clustername: "microk8s"
    kubectl:
      enabled: true
image:
  repository: infracloudio/botkube
  tag: v0.12.4' > botkube_values.yaml
```

```bash
helm repo add infracloudio https://infracloudio.github.io/charts
helm repo update
helm install botkube infracloudio/botkube \
--namespace botkube \
--create-namespace \
--values ./botkube_values.yaml
```

## Slack

```bash
@BotKube ping
@BotKube commands list
@BotKube get no --cluster-name="microk8s"
@BotKube get deployments --all-namespaces --cluster-name="microk8s"
```

**Fontes:**

<https://multipass.run/>

<https://microk8s.io/>

<https://grafana.com/>

<https://prometheus.io/>

<https://github.com/prometheus-community/helm-charts>

<https://www.botkube.io/>

<https://github.com/samber/awesome-prometheus-alerts>
