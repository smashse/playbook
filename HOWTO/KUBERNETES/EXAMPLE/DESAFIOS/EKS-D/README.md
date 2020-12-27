\*Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)

# Install KUBERNETES (EKS-D)

**OS:** UBUNTU

## Install VSCode

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

### Install Kubectl

```shell
sudo snap install kubectl --classic
```

### Install Amazon EKS Distro (EKS-D)

```shell
sudo snap install eks --classic --edge
```

```txt
eks (1.18/edge) v1.18.9 from Canonical✓ installed
```

### Check the status

```shell
eks status --wait-ready
```

```txt
eks is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
```

### Give execution permission to the current user

```shell
sudo usermod -a -G eks $USER
sudo chown -f -R $USER ~/.kube
```

### Export the current EKS-D configuration information for use with Kubectl

```shell
mkdir -p $HOME/.kube
sudo eks config > .kube/config
```

### Inspect the installation

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

### Check the version of Containerd

```shell
eks ctr --version
```

```txt
ctr github.com/containerd/containerd v1.3.7
```

### Server / Client version

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

### Access Kubernetes

EKS-D comes with its own version of Kubectl to access Kubernetes. Below we will cover 2 different forms of access to view the "nodes" and "services":

**Conventional**

```shell
eks kubectl get nodes
```

```txt
NAME           STATUS   ROLES    AGE   VERSION
myuser         Ready    <none>   33m   v1.18.9-eks-1-18-1
```

```shell
eks kubectl get services
```

```txt
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   33m
```

**Recommended**

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

_**Note:** As shown, the 2 forms have the same result, but from this point on we will only use the "Recommended" with Kubectl._

### Deploy a test application

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

## Starting and stopping EKS-D

EKS-D will continue to run until you decide to stop it. You can stop and start with the commands below:

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

## Basic information of your Kubernetes cluster

### Server/Client version

```shell
kubectl version --short=true
```

```txt
Client Version: v1.19.4
Server Version: v1.18.9-1+c787d4d0c397b8
```

### Cluster information

```shell
kubectl cluster-info
```

```txt
Kubernetes master is running at https://192.168.254.100:16443
CoreDNS is running at https://192.168.254.100:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://192.168.254.100:16443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```

### Configuration information

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

_**Note:** To view the access token, use the "--flatten=true" option._

### View the nodes

```shell
kubectl get nodes -w
```

```txt
NAME           STATUS   ROLES    AGE   VERSION
myuser         Ready    <none>   33h   v1.18.9-eks-1-18-1
```

### Information about a particular node

```shell
kubectl describe node myuser
```

## Source:

<https://microk8s.io/>

<https://microk8s.io/docs/commands>

<https://snapcraft.io/eks>

<https://snapcraft.io/kubectl>

<https://ubuntu.com/blog/install-amazon-eks-distro-anywhere>
