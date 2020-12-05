# Instalar o KUBERNETES

**SO BASE:** UBUNTU

## Instalar o VSCode
```bash
sudo snap install code --classic
```
```bash
code --install-extension AmazonWebServices.aws-toolkit-vscode
code --install-extension GitHub.github-vscode-theme
code --install-extension GoogleCloudTools.cloudcode
code --install-extension HashiCorp.terraform
code --install-extension MS-CEINTL.vscode-language-pack-pt-BR
code --install-extension Pivotal.vscode-boot-dev-pack
code --install-extension Pivotal.vscode-spring-boot
code --install-extension eamodio.gitlens
code --install-extension esbenp.prettier-vscode
code --install-extension formulahendry.docker-extension-pack
code --install-extension kde.breeze
code --install-extension ms-azuretools.vscode-azureterraform
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-aks-tools
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension ms-python.python
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code --install-extension ms-vscode.Theme-PredawnKit
code --install-extension ms-vscode.node-debug2
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension ms-vscode.vscode-typescript-tslint-plugin
code --install-extension redhat.fabric8-analytics
code --install-extension redhat.java
code --install-extension redhat.vscode-knative
code --install-extension redhat.vscode-yaml
code --install-extension vscoss.vscode-ansible
```

### Instalar o Kubectl
```bash
sudo snap install kubectl --classic
```

### Instalar o Kubernetes(MicroK8s)
```bash
sudo snap install microk8s --classic
```

### Verifique o status
```bash
sudo microk8s status --wait-ready
```

### Dar permissão de execução para o usuário atual
```bash
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
```

### Criar alias para o MicroK8s(Opcional)
```bash
alias mkctl='microk8s kubectl'
```

### Exportar as informações de configuração atuais de MicroK8s para uso com o Kubectl
```bash
mkdir -p $HOME/.kube
sudo microk8s config > .kube/config
```

### Acessar o Kubernetes

O MicroK8s vem com sua própria versão do Kubectl para acessar o Kubernetes. Abaixo iremos abordar 3 formas diferentes de acesso para visualizar os "nodes" e "services":

**Convencional**
```bash
microk8s kubectl get nodes
```
```txt
NAME           STATUS   ROLES    AGE   VERSION
myuser         Ready    <none>   17m   v1.19.3-34+a56971609ff35a
```

```bash
microk8s kubectl get services
```
```txt
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   18m
```

**Alias**
```bash
mkctl get nodes
```
```txt
NAME           STATUS   ROLES    AGE   VERSION
myuser         Ready    <none>   17m   v1.19.3-34+a56971609ff35a
```

```bash
mkctl get services
```
```txt
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   18m
```

**Recomendada**
```bash
kubectl get nodes
```
```txt
NAME           STATUS   ROLES    AGE   VERSION
myuser         Ready    <none>   17m   v1.19.3-34+a56971609ff35a
```

```bash
kubectl get services
```
```txt
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   18m
```

_**Observação:** Como demonstrado, as 3 formas tem o mesmo resultado porem deste ponto em diante iremos utilizar apenas a "Convencional" com o Kubectl._

### Implantar um aplicativo de teste

```bash
kubectl create deployment nginx --image=nginx
```
```txt
deployment.apps/nginx created
```

```bash
kubectl get pods
```
```txt
NAME                     READY   STATUS    RESTARTS   AGE
nginx-6799fc88d8-t4wlq   1/1     Running   0          22s
```

### Instalar Add-ons

Por uma questão de minimalismo, o MicroK8s instala apenas o necessário para um funcionamento mínimo do Kubernetes.

**Listar os Add-ons disponiveis**
```bash
sudo microk8s status
```
```txt
microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    ha-cluster           # Configure high availability on the current node
  disabled:
    ambassador           # Ambassador API Gateway and Ingress
    cilium               # SDN, fast with full network policy
    dashboard            # The Kubernetes dashboard
    dns                  # CoreDNS
    fluentd              # Elasticsearch-Fluentd-Kibana logging and monitoring
    gpu                  # Automatic enablement of Nvidia CUDA
    helm                 # Helm 2 - the package manager for Kubernetes
    helm3                # Helm 3 - Kubernetes package manager
    host-access          # Allow Pods connecting to Host services smoothly
    ingress              # Ingress controller for external access
    istio                # Core Istio service mesh services
    jaeger               # Kubernetes Jaeger operator with its simple config
    knative              # The Knative framework on Kubernetes.
    kubeflow             # Kubeflow for easy ML deployments
    linkerd              # Linkerd is a service mesh for Kubernetes and other frameworks
    metallb              # Loadbalancer for your Kubernetes cluster
    metrics-server       # K8s Metrics Server for API access to service metrics
    multus               # Multus CNI enables attaching multiple network interfaces to pods
    prometheus           # Prometheus operator for monitoring and logging
    rbac                 # Role-Based Access Control for authorisation
    registry             # Private image registry exposed on localhost:32000
    storage              # Storage class; allocates storage from host directory
```

**Habilitar Add-ons**
```bash
sudo microk8s enable dns ingress
```
```txt
Enabling DNS
Applying manifest
serviceaccount/coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created
clusterrole.rbac.authorization.k8s.io/coredns created
clusterrolebinding.rbac.authorization.k8s.io/coredns created
Restarting kubelet
DNS is enabled
Enabling Ingress
namespace/ingress created
serviceaccount/nginx-ingress-microk8s-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-microk8s-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-microk8s-role created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-microk8s created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-microk8s created
configmap/nginx-load-balancer-microk8s-conf created
configmap/nginx-ingress-tcp-microk8s-conf created
configmap/nginx-ingress-udp-microk8s-conf created
daemonset.apps/nginx-ingress-microk8s-controller created
Ingress is enabled
```

**Desabilitar Add-ons**
```bash
sudo microk8s disable dns ingress
```
```txt
Disabling DNS
Reconfiguring kubelet
Removing DNS manifest
serviceaccount "coredns" deleted
configmap "coredns" deleted
deployment.apps "coredns" deleted
service "kube-dns" deleted
clusterrole.rbac.authorization.k8s.io "coredns" deleted
clusterrolebinding.rbac.authorization.k8s.io "coredns" deleted
DNS is disabled
Disabling Ingress
Error from server (NotFound): deployments.apps "default-http-backend" not found
Error from server (NotFound): services "default-http-backend" not found
Error from server (NotFound): serviceaccounts "nginx-ingress-microk8s-serviceaccount" not found
Error from server (NotFound): roles.rbac.authorization.k8s.io "nginx-ingress-microk8s-role" not found
Error from server (NotFound): rolebindings.rbac.authorization.k8s.io "nginx-ingress-microk8s" not found
Error from server (NotFound): configmaps "nginx-load-balancer-microk8s-conf" not found
Error from server (NotFound): daemonsets.apps "nginx-ingress-microk8s-controller" not found
namespace "ingress" deleted
serviceaccount "nginx-ingress-microk8s-serviceaccount" deleted
clusterrole.rbac.authorization.k8s.io "nginx-ingress-microk8s-clusterrole" deleted
role.rbac.authorization.k8s.io "nginx-ingress-microk8s-role" deleted
clusterrolebinding.rbac.authorization.k8s.io "nginx-ingress-microk8s" deleted
rolebinding.rbac.authorization.k8s.io "nginx-ingress-microk8s" deleted
configmap "nginx-load-balancer-microk8s-conf" deleted
configmap "nginx-ingress-tcp-microk8s-conf" deleted
configmap "nginx-ingress-udp-microk8s-conf" deleted
daemonset.apps "nginx-ingress-microk8s-controller" deleted
Ingress is disabled
```

### Iniciando e parando MicroK8s

O MicroK8s continuará em execução até que você decida interrompê-lo. Você pode parar e iniciar com os comandos abaixo:

```bash
sudo microk8s stop
```
```txt
Stopped.
```

```bash
sudo microk8s start
```
```txt
Started.
```

## Informaçoes basicas do seu cluster Kubernetes

### Versão do servidor/cliente
```shell
kubectl version --short=true
```
```txt
Client Version: v1.19.4
Server Version: v1.19.3-34+a56971609ff35a
```

### Informações do cluster
```shell
kubectl cluster-info
```
```txt
Kubernetes master is running at https://192.168.254.100:16443
CoreDNS is running at https://192.168.254.100:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### Informações de configuração
```shell
kubectl config view
```
```txt
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.254.100:16443
  name: microk8s-cluster
contexts:
- context:
    cluster: microk8s-cluster
    user: admin
  name: microk8s
current-context: microk8s
kind: Config
preferences: {}
users:
- name: admin
  user:
    token: REDACTED
```

_**Observação:** Para visualizar o token de acesso, utilize a opção "--flatten=true"._

### Visualize os nodes
```shell
kubectl get nodes -w
```
```txt
NAME        STATUS   ROLES    AGE   VERSION
microk8s    Ready    <none>   22h   v1.19.3-34+a56971609ff35a
```

### Informaçòes sobre um node em particular
```shell
kubectl describe node microk8s
```

## Namespaces
O namespace fornece um escopo para nomes. O uso de vários namespaces é opcional.

### Listar Namespaces
```shell
kubectl get namespaces
```

OU

```shell
kubectl get ns
```

```txt
NAME              STATUS   AGE
kube-system       Active   148m
kube-public       Active   148m
kube-node-lease   Active   148m
default           Active   148m
ingress           Active   146m
```

### Criar Namespaces
```shell
kubectl create namespace teste
```

OU

```shell
kubectl create ns teste
```

```
namespace/teste created
```

### Exibir detalhes do Namespace
```shell
kubectl describe namespace teste
```

OU

```shell
kubectl describe ns teste
```

```txt
Name:         teste
Labels:       <none>
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

### Remover Namespaces
```shell
kubectl delete namespace teste
```

OU

```shell
kubectl delete ns teste
```

```txt
namespace "teste" deleted
```

## Fonte:

<https://microk8s.io/>

<https://microk8s.io/docs/commands>

<https://snapcraft.io/kubectl>
