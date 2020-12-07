# Instalar o KUBERNETES (EKS-D)

**SO BASE:** UBUNTU

## Instalar o VSCode

```shell
sudo snap install code --classic
```

```shell
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

```shell
sudo snap install kubectl --classic
```

### Instalar o Amazon EKS Distro(EKS-D)
```shell
sudo snap install eks --classic --edge
```
```txt
eks (1.18/edge) v1.18.9 from Canonical✓ installed
```

### Verifique o status
```shell
eks status --wait-ready
```
```txt
eks is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
```

### Dar permissão de execução para o usuário atual

```shell
sudo usermod -a -G eks $USER
sudo chown -f -R $USER ~/.kube
```

### Exportar as informações de configuração atuais de EKS-D para uso com o Kubectl

```shell
mkdir -p $HOME/.kube
sudo eks config > .kube/config
```

### Inspecionar a instalação
```shell
eks inspect | grep running
```
```txt
  Service snap.eks.daemon-cluster-agent is running
  Service snap.eks.daemon-containerd is running
  Service snap.eks.daemon-apiserver is running
  Service snap.eks.daemon-apiserver-kicker is running
  Service snap.eks.daemon-control-plane-kicker is running
  Service snap.eks.daemon-proxy is running
  Service snap.eks.daemon-kubelet is running
  Service snap.eks.daemon-scheduler is running
  Service snap.eks.daemon-controller-manager is running
```

### Verificar a versão do Containerd
```shell
eks ctr --version
```
```txt
ctr github.com/containerd/containerd v1.3.7
```

### Versão do servidor/cliente
```shell
eks ctr version
```
```txt
Client:
  Version:  v1.3.7
  Revision: 8fba4e9a7d01810a393d5d25a3621dc101981175

Server:
  Version:  v1.3.7
  Revision: 8fba4e9a7d01810a393d5d25a3621dc101981175
  UUID: 339017b3-570e-43bd-a528-4a08123868ca
```

### Acessar o Kubernetes

O EKS-D vem com sua própria versão do Kubectl para acessar o Kubernetes. Abaixo iremos abordar 3 formas diferentes de acesso para visualizar os "nodes" e "services":

**Convencional**

```shell
eks kubectl get nodes
```
```txt
NAME           STATUS   ROLES    AGE   VERSION
andersongama   Ready    <none>   33m   v1.18.9-eks-1-18-1
```

```shell
eks kubectl get services
```
```txt
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   33m
```

**Recomendada**

```shell
kubectl get nodes
```
```txt
NAME           STATUS   ROLES    AGE   VERSION
myuser         Ready    <none>   33m   v1.18.9-eks-1-18-1
```

```shell
kubectl get services
```
```txt
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   33m
```

_**Observação:** Como demonstrado, as 2 formas tem o mesmo resultado porem deste ponto em diante iremos utilizar apenas a "Recomendada" com o Kubectl._

### Implantar um aplicativo de teste

```shell
kubectl create deployment nginx --image=nginx
```
```txt
deployment.apps/nginx created
```

```shell
kubectl get pods
```
```txt
NAME                    READY   STATUS    RESTARTS   AGE
nginx-f89759699-2w75l   1/1     Running   0          33s
```

## Iniciando e parando EKS-D

O EKS-D continuará em execução até que você decida interrompê-lo. Você pode parar e iniciar com os comandos abaixo:

```shell
sudo eks stop
```

```txt
Stopped.
```

```shell
sudo eks start
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
Server Version: v1.18.9-1+c787d4d0c397b8
```

### Informações do cluster

```shell
kubectl cluster-info
```

```txt
Kubernetes master is running at https://192.168.254.100:16443
CoreDNS is running at https://192.168.254.100:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://192.168.254.100:16443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

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
NAME           STATUS   ROLES    AGE   VERSION
myuser         Ready    <none>   33h   v1.18.9-eks-1-18-1
```

### Informaçòes sobre um node em particular

```shell
kubectl describe node myuser
```