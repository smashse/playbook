_Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)_

# Lightweight Kubernetes Deployment with Kustomize + Kapp

---

## 1. Overview and Philosophy

**kapp** is a command-line tool (CLI) focused on managing the application lifecycle in Kubernetes. Instead of operating as a template engine or a continuous in-cluster operator, `kapp` treats sets of declarative resources as a unified application.

The **Kustomize + kapp** approach establishes a clear separation of concerns:

```text
┌────────────────────────────────┐     ┌────────────────────────────────┐     ┌────────────────────────────────┐
│           Kustomize            │     │              kapp              │     │         Kubernetes API         │
│       Manifest Rendering       │ ──> │    Deployment Orchestration    │ ──> │    Desired State Execution     │
│  (Pure YAML Transformations)   │     │  (Diff, Pruning, Dependencies) │     │  (GKE / EKS / AKS / On-Prem)   │
└────────────────────────────────┘     └────────────────────────────────┘     └────────────────────────────────┘
```

- **Kustomize:** Concatenates, modifies, and generates static YAML manifests without introducing complex templating syntax.
- **kapp:** Compares manifests against the cluster's current state, displays an accurate diff, applies changes in the correct order, waits for service readiness, and prunes obsolete objects.
- **Kubernetes Cluster:** Executes workloads exclusively. Requires no additional controllers running in the background to process deployments.

---

## 2. Problems and Pain Points Solved

### A. Limitations of `kubectl apply`

- **Lack of Safe Pruning:** `kubectl apply --prune` is prone to deleting unintended resources because it relies solely on labels, making it unsafe for production use.
- **Asynchronous Execution:** `kubectl` submits manifests to the API and exits. It does not wait for Pod initialization, Health Checks, or Volume Attachments, complicating control in CI/CD pipelines.
- **Absence of Dependency Ordering:** There is no native guarantee that a `CustomResourceDefinition` (CRD) or `ConfigMap` is created and ready before a `Deployment` is started.

### B. Complexity of Traditional GitOps (Argo CD / Flux)

- **Infrastructure Overhead:** Requires running multiple controllers, Pods, and CRDs inside the cluster, consuming memory and CPU solely to maintain the reconciliation loop.
- **Difficulty in Previewing Diff:** In auto-sync GitOps models, deployment occurs after the commit. Interactively validating the exact diff of a change prior to applying it to the cluster becomes a more complex process.

### C. Helm Fragilities

- **Syntax Injection via Go Templates:** String interpolation in YAML files can cause indentation failures and errors that are difficult to debug in automated pipelines.
- **Masked State:** Helm release history is hidden inside Base64-encoded Secrets, making direct auditing via native Kubernetes tools more difficult.

---

## 3. Technical Comparison of Solutions

| Criterion                        | `kubectl apply`              | Helm                          | Argo CD / Flux          | Kustomize + kapp                             |
| -------------------------------- | ---------------------------- | ----------------------------- | ----------------------- | -------------------------------------------- |
| **In-Cluster Controllers**       | None                         | None                          | Multiple operators/CRDs | **None (0 in-cluster controllers)**          |
| **Manifest Generation**          | Pure YAML                    | Go Templates                  | Native Helm / Kustomize | **Kustomize (Declarative YAML)**             |
| **Diff Calculation**             | Superficial (`kubectl diff`) | Requires plugin (`helm diff`) | Web UI / PRs            | **Native, detailed, and interactive**        |
| **Readiness Guarantee**          | Does not wait                | Partial (`--wait`)            | Managed by Operator     | **Waits for state convergence by default**   |
| **Resource Cleanup (_Pruning_)** | Manual / Dangerous           | Limited to Release scope      | Automatic via GitOps    | **Automatic, explicit in diff, and tracked** |
| **Primary Execution**            | Local / CI/CD                | Local / CI/CD                 | Inside Cluster          | **Local / CI/CD**                            |

---

## 4. Architecture and Operational Flow

`kapp` does not rely on an external database. Calculating the impact of a change is done through a **triple-read**:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                        Evaluation Process (Diff)                        │
├──────────────────────────┬──────────────────────────┬───────────────────┤
│     1. Desired State     │     2. Stored State      │  3. Current State │
│    (Kustomize Output)    │   (kapp ConfigMap)       │   (Kubernetes API)│
└────────────┬─────────────┴────────────┬─────────────┴─────────┬─────────┘
             │                          │                       │
             └──────────────────────────┼───────────────────────┘
                                        ▼
                           ┌────────────────────────┐
                           │ Operations Calculation │
                           │  (create, update,      │
                           │   delete, noop)        │
                           └────────────────────────┘
```

1. **Desired State:** Manifests rendered by `kustomize build`.
2. **Stored State:** A `ConfigMap` managed by `kapp` that stores the list and metadata of all resources belonging to that specific application.
3. **Current State (_Live State_):** Real-time query to the Kubernetes API to identify external changes (_drift_).

### Automatic Ordering (_Apply Ordering_)

`kapp` implicitly calculates the correct application order for resources (e.g., `Namespaces` -> `CRDs` -> `ConfigMaps/Secrets` -> `Deployments/StatefulSets` -> `Services`). It also allows custom rules to be defined via annotations (`kapp.k14s.io/change-group` and `kapp.k14s.io/change-rule`).

---

## 5. Practical Hands-On Lab (PoC): Environment Setup with Multipass + MicroK8s

To simulate a real workflow, the Multipass VM will solely run the Kubernetes cluster (MicroK8s), while the management tools (`kustomize` and `kapp`) will run directly on your local machine (Host).

### Create the Cloud-Init Definition

```bash
echo '#cloud-config
runcmd:
- apt update --fix-missing
- snap refresh
- snap install microk8s --classic
- microk8s status --wait-ready
- microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

### Create the Virtual Machine

```bash
multipass launch focal -n microk8s -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
```

### Create Directory for Kubeconfig Settings on Host

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Export Cluster Configuration to Host

```bash
multipass exec microk8s sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

### Redirect API Endpoint to VM's Real IP

```bash
VM_IP=$(multipass info microk8s | grep IPv4 | awk '{print $2}')
sed -i "s/127.0.0.1/${VM_IP}/g" $HOME/.kube/configs/config-microk8s
```

### Set the KUBECONFIG Environment Variable

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

### Set Restricted File Permissions

```bash
chmod 0600 $KUBECONFIG
```

### Validate Context on Host

```bash
kubectl config get-contexts
```

```text
CURRENT   NAME       CLUSTER            AUTHINFO   NAMESPACE
*         microk8s   microk8s-cluster   admin
```

### Validate Connection to Cluster

```bash
kubectl get nodes
```

```text
NAME       STATUS   ROLES    AGE     VERSION
microk8s   Ready    <none>   2m15s   v1.31.1
```

---

## 6. CLI Installation on Host (Kustomize + kapp)

Declarative versioning and rendering operations take place exclusively on your development machine.

### Install Kustomize (Official Binary)

```bash
curl -s "[https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh](https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh)" | bash
sudo mv kustomize /usr/local/bin/
```

### Install kapp (Carvel Suite)

```bash
curl -L [https://carvel.dev/install.sh](https://carvel.dev/install.sh) | sudo bash
```

---

## 7. Application Structure and Deployment (Declarative Kustomize)

Organizing manifests into base and overlays for local testing.

```text
poc-kapp/
└── deploy/
    ├── base/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── overlays/
        └── local/
            └── kustomization.yaml
```

### Create Directories

```bash
mkdir -p poc-kapp/deploy/base poc-kapp/deploy/overlays/local
cd poc-kapp
```

### Create Base Deployment Manifest (`deploy/base/deployment.yaml`)

```bash
cat <<EOF> deploy/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: valkey
spec:
  replicas: 1
  selector:
    matchLabels:
      app: valkey
  template:
    metadata:
      labels:
        app: valkey
    spec:
      containers:
      - name: valkey
        image: valkey/valkey:8.0-alpine
        ports:
        - containerPort: 6379
EOF
```

### Create Base Service Manifest (`deploy/base/service.yaml`)

```bash
cat <<EOF> deploy/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: valkey
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: valkey
EOF
```

### Create Base Kustomization (`deploy/base/kustomization.yaml`)

```bash
cat <<EOF> deploy/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
EOF
```

### Create Local Overlay (`deploy/overlays/local/kustomization.yaml`)

```bash
cat <<EOF> deploy/overlays/local/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: valkey-poc
resources:
- "../../base"
patches:
- patch: |-
    - op: replace
      path: /spec/replicas
      value: 2
  target:
    kind: Deployment
    name: valkey
EOF
```

---

## 8. Executing the PoC with kapp (Host -> VM)

### Perform Initial Deployment

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local)
```

```text
Target cluster: [https://192.168.64.5:16443](https://192.168.64.5:16443) (microk8s-cluster)

Namespace   Name        Kind        Op      Op st.  Wait to
(cluster)   valkey-poc  Namespace   create  -       reconcile
valkey-poc  valkey      Service     create  -       reconcile
valkey-poc  valkey      Deployment  create  -       reconcile

Op:      3 create, 0 delete, 0 update, 0 noop
Wait to: 3 reconcile

Continue? [yN]: y
```

### Inspection and Operation Commands

```bash
# List managed applications in the cluster
kapp list
```

```bash
# View resource tree
kapp inspect -a valkey-app --tree
```

```bash
# Tail aggregated logs for all Pods in the application
kapp logs -a valkey-app -f
```

### Test Diff Calculation (Scaling + Image)

```bash
cat <<EOF> deploy/overlays/local/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: valkey-poc
resources:
- "../../base"
patches:
- patch: |-
    - op: replace
      path: /spec/replicas
      value: 3
  target:
    kind: Deployment
    name: valkey
images:
- name: valkey/valkey
  newTag: "8.0"
EOF
```

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local) --diff-changes
```

### Test Automatic Pruning (Service Removal)

```bash
sed -i '/- service.yaml/d' deploy/base/kustomization.yaml
```

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local)
```

```text
Target cluster: [https://192.168.64.5:16443](https://192.168.64.5:16443) (microk8s-cluster)

Namespace   Name    Kind     Op      Op st.  Wait to
valkey-poc  valkey  Service  delete  -       reconcile

Op:      0 create, 1 delete, 0 update, 0 noop
Wait to: 1 reconcile

Continue? [yN]: y
```

---

## 9. Integration into CI/CD Pipelines

Being a stateless command-line tool, **kapp** is ideal for continuous integration and continuous delivery (CI/CD) pipelines. It replaces `kubectl apply` with decisive advantages for automation:

```text
  [ Push / Merge Request ]
             │
             ▼
┌──────────────────────────┐     1. Git Repository Checkout
│                          │ ──> 2. Rendering: kustomize build
│   CI/CD Runner           │ ──> 3. Validation: kapp deploy --diff-run
│   (GitHub/GitLab/Jenkins)│ ──> 4. Application: kapp deploy --yes
└──────────────────────────┘
             │ (HTTPS / Kubeconfig)
             ▼
┌──────────────────────────┐
│   Kubernetes Cluster     │
└──────────────────────────┘
```

### Automation Advantages

1. **Synchronous Feedback:** `kapp` waits for state convergence (_health check_). If a Pod fails to initialize during deployment, the CI/CD job **fails immediately**.
2. **Pre-validation in Pull Requests:** Using the `--diff-run` flag to predict exactly which objects will be modified without applying changes to the cluster.
3. **Safe Pruning:** Resources removed from the Git repository are deleted from the cluster in a controlled manner during pipeline execution.

---

### Example 1: GitHub Actions Pipeline (`.github/workflows/deploy.yaml`)

```yaml
name: Continuous Deployment

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install Kustomize and kapp
        run: |
          curl -s "[https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh](https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh)" | bash
          sudo mv kustomize /usr/local/bin/
          curl -L [https://carvel.dev/install.sh](https://carvel.dev/install.sh) | sudo bash

      - name: Configure Kubeconfig
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG_DATA }}

      - name: Render and Deploy via kapp
        run: |
          kustomize build deploy/overlays/production | kapp deploy \
            --app valkey-app \
            --namespace production \
            --file - \
            --yes
```

---

### Example 2: GitLab CI Pipeline (`.gitlab-ci.yml`)

```yaml
stages:
  - validate
  - deploy

.kapp-setup: &kapp-setup
  before_script:
    - curl -s "[https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh](https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh)" | bash && mv kustomize /usr/local/bin/
    - curl -L [https://carvel.dev/install.sh](https://carvel.dev/install.sh) | bash
    - mkdir -p ~/.kube && echo "$KUBE_CONFIG_DATA" > ~/.kube/config

# Diff Validation in Merge Requests
preview-diff:
  stage: validate
  <<: *kapp-setup
  script:
    - kustomize build deploy/overlays/production | kapp deploy -a valkey-app -n production -f - --diff-run
  only:
    - merge_requests

# Production Deployment
deploy-production:
  stage: deploy
  <<: *kapp-setup
  script:
    - kustomize build deploy/overlays/production | kapp deploy -a valkey-app -n production -f - --yes
  only:
    - main
```

---

### CI/CD Best Practices

- **`--yes` (`-y`) Flag:** Always include the `--yes` flag in deployment jobs to disable interactive terminal prompts.
- **Utility Containers:** Use custom Docker images pre-installing `kustomize` and `kapp` to reduce pipeline execution time.
- **Short-Lived Authentication (OIDC):** Prefer OIDC (OpenID Connect) authentication with your cloud provider instead of storing static `kubeconfig` files in repository secrets.

---

## 10. State Management, Backup, and Disaster Recovery

### State Storage

The state of each application is maintained in a `ConfigMap` within Kubernetes, using the naming convention `<app-name>.apps.k14s.io` inside the target namespace.

### A. State Backup Strategy

To export the current state managed by `kapp`:

```bash
#!/usr/bin/env bash
BACKUP_DIR="./backups/kapp"
mkdir -p "${BACKUP_DIR}"

kubectl get configmap -n valkey-poc -l kapp.k14s.io/app \
  -o yaml > "${BACKUP_DIR}/kapp-state-valkey-$(date +%Y%m%d).yaml"
```

### B. Disaster Recovery (DR) Procedures

#### Scenario 1: Accidental Deletion of State ConfigMap

If the control `ConfigMap` for `kapp` is removed, the application's Pods and services **will not be affected**. To restore tracking:

1. Run the deploy command pointing to the Git manifest:

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local) --yes
```

2. `kapp` will identify existing resources in the Kubernetes API and **re-adopt** all objects without causing disruptions to running Pods.

#### Scenario 2: Total Cluster Rebuild

In case of total cluster loss:

1. Restoration does not depend on the old `ConfigMap` backup, as the primary source of truth is the **Git** repository.
2. After rebuilding the cluster, run the deployment pipeline:

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local) --yes
```

3. `kapp` will recreate Namespaces, ConfigMaps, Secrets, Workloads, and Services respecting the dependency tree.

---

## 11. Cleanup (Teardown)

### Remove Application from Cluster

```bash
kapp delete -a valkey-app
```

### Destroy VM in Multipass

```bash
multipass delete microk8s
multipass purge
```

---

## 12. Official Sources, Licensing, and Maturity Status

### **kapp (Carvel Suite)**

- **Official Documentation:** [carvel.dev/kapp](https://carvel.dev/kapp/)
- **Source Code Repository:** [github.com/carvel-dev/kapp](https://github.com/carvel-dev/kapp)
- **Software License:** Apache License 2.0 (Open Source)
- **Maturity Status:** **CNCF Sandbox Project** (part of the Carvel suite accepted by the Cloud Native Computing Foundation).

### **Kustomize**

- **Official Documentation:** [kustomize.io](https://kustomize.io/) | [kubectl-docs.kubernetes.io](https://www.google.com/search?q=https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- **Source Code Repository:** [github.com/kubernetes-sigs/kustomize](https://github.com/kubernetes-sigs/kustomize)
- **Software License:** Apache License 2.0 (Open Source)
- **Maturity Status:** **Kubernetes SIG Project / Official Subproject** (subproject maintained by the Kubernetes Special Interest Group and natively integrated into the `kubectl kustomize` subcommand since Kubernetes version 1.14).

### **Mentioned Tools**

- **Helm:** [helm.sh](https://helm.sh/) | Apache License 2.0 | Status: **CNCF Graduated Project**
- **Argo CD:** [argoproj.github.io/cd](https://argoproj.github.io/cd/) | Apache License 2.0 | Status: **CNCF Graduated Project**
- **Flux:** [fluxcd.io](https://fluxcd.io/) | Apache License 2.0 | Status: **CNCF Graduated Project**
