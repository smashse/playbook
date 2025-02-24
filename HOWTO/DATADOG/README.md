# Proof of Concept (POC) Requirements

In this POC, we will use **Multipass** to create instances for installing **DataDog** and **MicroK8s**. The goal is to establish DataDog as an observability tool for the Kubernetes cluster provisioned with MicroK8s.

## 1. Install Multipass

To install Multipass, run the following command:

```bash
sudo snap install multipass --classic
```

## 2. MicroK8s Setup

MicroK8s is the smallest, fastest, fully-conformant Kubernetes distribution that tracks upstream releases and simplifies clustering. It is ideal for offline development, prototyping, and testing.

### 2.1 Create a MicroK8s Template

Create a `cloud-config-microk8s.yaml` file to configure the MicroK8s instance:

```bash
echo '#cloud-config
runcmd:
  - apt update --fix-missing
  - snap refresh
  - snap install microk8s --classic
  - microk8s status --wait-ready
  - microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

### 2.2 Create a MicroK8s Instance

Launch a MicroK8s instance using Multipass:

```bash
multipass launch noble -n microk8s -c 3 -m 6G -d 10G --cloud-init cloud-config-microk8s.yaml
```

### 2.3 Export MicroK8s Configuration for Kubectl

#### 2.3.1 Create a Directory for Kubernetes Configurations

```bash
mkdir -p $HOME/.kube/configs
```

#### 2.3.2 Export MicroK8s Configuration

Export the MicroK8s configuration to the created directory:

```bash
multipass exec microk8s -- sudo microk8s config | tee $HOME/.kube/configs/config-microk8s
```

#### 2.3.3 Set the Exported Configuration as Default for Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
chmod 0600 $KUBECONFIG
```

#### 2.3.4 Install Kubectl

Install Kubectl using Snap:

```bash
sudo snap install kubectl --classic
```

Verify the installation:

```bash
kubectl get no
```

#### 2.3.5 Install Helm

```bash
sudo snap install helm --classic
```

**Output:**

```txt
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   10m   v1.32.1
```

### 2.4 Add an IP Alias for MicroK8s

Add an IP alias for the MicroK8s instance to `microk8s.local`:

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.local/' | sudo tee -a /etc/hosts
```

### 2.5 Access MicroK8s via URL

You can access MicroK8s via the following URL:  
<http://microk8s.local>

## 3. DataDog Setup

<details>
<summary><b>Differences Between US1, US3, and US5 in Datadog</b></summary>

In Datadog, **US1**, **US3**, and **US5** refer to different **regions (endpoints)** where data is processed and stored. These regions are designed to serve customers in specific geographic locations or to meet compliance requirements. Below are the main differences:

---

### **US1 (US Region - Default)**

- **Endpoint**: `https://datadoghq.com`
- **Description**: The primary and default Datadog region for customers in the United States.
- **Data Residency**: Data is stored and processed in the United States.
- **Use Case**: Ideal for customers who do not have specific data residency requirements outside the US.
- **Performance**: Best performance for users and applications located in the US.

---

### **US3 (US3 Region)**

- **Endpoint**: `https://us3.datadoghq.com`
- **Description**: A separate Datadog region, also located in the United States, but isolated from US1.
- **Data Residency**: Data is stored and processed in the United States, but in a different infrastructure than US1.
- **Use Case**: Designed for customers who need isolation from the primary US1 region, often for compliance, regulatory, or organizational reasons.
- **Performance**: Similar to US1 for users and applications in the US.

---

### **US5 (US5 Region)**

- **Endpoint**: `https://us5.datadoghq.com`
- **Description**: Another isolated Datadog region in the United States, distinct from US1 and US3.
- **Data Residency**: Data is stored and processed in the United States, but in a separate infrastructure.
- **Use Case**: Used by customers who require additional isolation or have specific compliance needs that cannot be met by US1 or US3.
- **Performance**: Comparable to US1 and US3 for users and applications in the US.

---

### Key Differences:

| Feature         | US1                    | US3                        | US5                        |
| --------------- | ---------------------- | -------------------------- | -------------------------- |
| **Endpoint**    | `datadoghq.com`        | `us3.datadoghq.com`        | `us5.datadoghq.com`        |
| **Location**    | US (Primary)           | US (Isolated)              | US (Isolated)              |
| **Use Case**    | Default US region      | Compliance/isolation needs | Additional isolation needs |
| **Performance** | Optimized for US users | Optimized for US users     | Optimized for US users     |

---

### How to Choose the Right Region:

- **US1**: Use this region if you do not have specific compliance or isolation requirements.
- **US3/US5**: Use these regions if you need isolated infrastructure to meet compliance, regulatory, or organizational requirements.

---

### Note:

- Data and configurations are **not shared** between these regions. If you switch regions, you will need to set up your Datadog environment (dashboards, monitors, etc.) separately.
- Ensure that data ingestion and API calls are directed to the correct endpoint for your chosen region.

[Getting Started with Datadog Sites](https://docs.datadoghq.com/getting_started/site/)

</details>

### 3.1 Getting Started with DataDog Free Tier

1. Visit [Datadog's website](https://www.datadoghq.com).
2. Create a free account.
3. Follow the instructions to install the Datadog Agent in your environment (on-premises or in the cloud).

### 3.2 Install the Datadog Agent

The Datadog Agent collects metrics and events from your systems and apps. Install at least one Agent anywhere, even on your workstation.

#### 3.2.1 Installing on Kubernetes

<details>
<summary><b>Option 1: Using the Datadog Operator</b></summary>

The Datadog Operator is a way to deploy the Datadog Agent on Kubernetes and OpenShift. It simplifies deployment and reduces the risk of misconfiguration.

##### 3.2.1.1 Install the Datadog Operator

Install the Datadog Operator in the current namespace:

```bash
helm repo add datadog https://helm.datadoghq.com
helm install datadog-operator datadog/datadog-operator
kubectl create secret generic datadog-secret --from-literal api-key="YOUR_API-KEY"
```

##### 3.2.1.2 Configure `datadog-agent.yaml`

To configure the Datadog Agent on AKS, Openshift, and TKG distributions refer to [Kubernetes distributions documentation](https://docs.datadoghq.com/containers/kubernetes/distributions/?tab=operator).

Configure the Datadog Agent for your Kubernetes distribution:

```bash
echo 'apiVersion: "datadoghq.com/v2alpha1"
kind: "DatadogAgent"
metadata:
  name: "datadog"
spec:
  global:
    clusterName: "microk8s"
    site: "us5.datadoghq.com"
    credentials:
      apiSecret:
        secretName: "datadog-secret"
        keyName: "api-key"
  features:
    apm:
      instrumentation:
        enabled: true
        libVersions:
          java: "1"
          dotnet: "3"
          python: "2"
          js: "5"
    logCollection:
      enabled: true
      containerCollectAll: true
    asm:
      threats:
        enabled: true
      sca:
        enabled: true
      iast:
        enabled: true
    cws:
      enabled: true
    usm:
      enabled: true
    npm:
      enabled: true' | tee datadog-agent.yaml
```

##### 3.2.1.3 Deploy the Datadog Agent

Apply the configuration:

```bash
kubectl apply -f datadog-agent.yaml
```

##### 3.2.1.4 Confirm Agent Installation

Query the pods to confirm the installation:

```bash
kubectl get pods -l app.kubernetes.io/component=agent
kubectl get pods -l app.kubernetes.io/managed-by=datadog-operator
```

</details>

<details>
<summary><b>Option 2: Using the Helm Chart</b></summary>

You can use the Datadog Helm chart to install the Datadog Agent across all nodes in your cluster via a DaemonSet.

##### 3.2.2.1 Add the Datadog Helm Repository

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
kubectl create secret generic datadog-secret --from-literal api-key="YOUR_API-KEY"
```

##### 3.2.2.2 Configure `datadog-values.yaml`

To configure the Datadog Agent on AKS, Openshift, and TKG distributions refer to [Kubernetes distributions documentation](https://docs.datadoghq.com/containers/kubernetes/distributions/?tab=helm).

Configure the Datadog Agent for your Kubernetes distribution:

```bash
echo 'datadog:
  apiKeyExistingSecret: "datadog-secret"
  site: "us5.datadoghq.com"
  apm:
    instrumentation:
      enabled: true
      libVersions:
        java: "1"
        dotnet: "3"
        python: "2"
        js: "5"
  logs:
    enabled: true
    containerCollectAll: true
  asm:
    threats:
      enabled: true
    sca:
      enabled: true
    iast:
      enabled: true
  securityAgent:
    runtime:
      enabled: true
  serviceMonitoring:
    enabled: true
  networkMonitoring:
    enabled: true' | tee datadog-values.yaml
```

##### 3.2.2.3 Deploy the Datadog Agent

Install the Datadog Agent using Helm:

```bash
helm install datadog-agent -f datadog-values.yaml datadog/datadog
```

##### 3.2.2.4 Confirm Agent Installation

Query the pods to confirm the installation:

```bash
kubectl get pods -l app.kubernetes.io/component=agent
kubectl get pods -l app.kubernetes.io/managed-by=Helm
```

</details>
