*Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)*

# Install KUBERNETES (MicroK8s)

**BASE OS:** UBUNTU

## Create extensions list for VSCode/Codium

```bash
echo "GitHub.github-vscode-theme
HashiCorp.terraform
HashiCorp.HCL
MS-CEINTL.vscode-language-pack-pt-BR
eamodio.gitlens
esbenp.prettier-vscode
ms-vscode.Theme-PredawnKit
ms-vscode.node-debug2
ms-vscode.vscode-typescript-next
ms-vscode.vscode-typescript-tslint-plugin
redhat.vscode-yaml" > vscode.list
```

## Install VSCode

```bash
sudo snap install code --classic
```

```bash
for i in `cat vscode.list` ; do code --install-extension $i --force ; done
```

OR

## Install Codium

```bash
sudo snap install codium --classic
```

```bash
for i in `cat vscode.list` ; do codium --install-extension $i --force ; done
```

### Install Kubectl

```bash
sudo snap install kubectl --classic
```

### Install Kubernetes(MicroK8s)

```bash
sudo snap install microk8s --classic
```

### Check status

```bash
sudo microk8s status --wait-ready
```

### Give execution permission to the current user

```bash
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
```

### Reload user groups

```bash
newgrp microk8s
```

### Create alias for MicroK8s(Optional)

```bash
alias mkctl='microk8s kubectl'
```

### Export current MicroK8s configuration information for use with Kubectl

```bash
mkdir -p $HOME/.kube
sudo microk8s config > $HOME/.kube/config
```

### Access Kubernetes

MicroK8s comes with its own version of Kubectl to access Kubernetes. Below we will cover 3 different ways to access and view "nodes" and "services":

**Conventional**

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
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   33m
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
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   33m
```

**Recommended**

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
kubernetes   ClusterIP   10.152.183.1   <none>        443/TCP   33m
```

_**Note:** As demonstrated, the 3 ways have the same result, however from this point on we will only use the "Recommended" one with Kubectl._

### Deploy a test application

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
nginx-6799fc88d8-t4wlq   1/1     Running   0          33s
```

### Install Add-ons

For minimalism, MicroK8s installs only what is necessary for minimal Kubernetes operation.

**List available Add-ons**

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

**Enable Add-ons**

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

**Disable Add-ons**

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

### Starting and stopping MicroK8s

MicroK8s will continue to run until you decide to stop it. You can stop and start it with the commands below:

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

## Basic information about your Kubernetes cluster

### Server/client version

```bash
kubectl version --short=true
```

```txt
Client Version: v1.19.4
Server Version: v1.19.3-34+a56971609ff35a
```

### Cluster information

```bash
kubectl cluster-info
```

```txt
Kubernetes master is running at https://192.168.254.100:16443
CoreDNS is running at https://192.168.254.100:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### Configuration information

```bash
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

### View nodes

```bash
kubectl get nodes -w
```

```txt
NAME        STATUS   ROLES    AGE   VERSION
myuser      Ready    <none>   33h   v1.19.3-34+a56971609ff35a
```

### Information about a particular node

```bash
kubectl describe node myuser
```

## Namespaces

Namespace provides a scope for names. Using multiple namespaces is optional.

### List Namespaces

```bash
kubectl get namespaces
```

OR

```bash
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

### Create Namespaces

```bash
kubectl create namespace test
```

OR

```bash
kubectl create ns test
```

    namespace/test created

### Display Namespace details

```bash
kubectl describe namespace test
```

OR

```bash
kubectl describe ns test
```

```txt
Name:         test
Labels:       <none>
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

### Remove Namespaces

```bash
kubectl delete namespace test
```

OR

```bash
kubectl delete ns test
```

```txt
namespace "test" deleted
```

[For creating other resources manually and via YAML.](./RESOURCES.md)

## Source:

<https://microk8s.io/>

<https://microk8s.io/docs/commands>

<https://snapcraft.io/kubectl>
