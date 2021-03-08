This POC (Proof of Concept) will use [Ubuntu](https://ubuntu.com/) as the base OS, [Multipass](https://multipass.run/), [MicroK8s](https://microk8s.io/), [MinIO](https://min.io/) and [Velero](https://velero.io/) to backup the resources present in a [Kubernetes](https://kubernetes.io/) namespace to a bucket.

# Multipass

Multipass is a mini-cloud on your workstation using native hypervisors of all the supported plaforms (Windows, macOS and Linux). Multipass can launch and run virtual machines and configure them with [cloud-init](https://cloud-init.io/) like a public cloud.

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
 - microk8s enable dns ingress metrics-server prometheus' > cloud-config-microk8s.yaml
```

## Create a MicroK8s instance

```bash
multipass launch focal -n teste -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
```

## Export the current MicroK8s configuration information for use with Kubectl

### Create the folder to store the configuration of the Kubernetes cluster in the test instance

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Export the MicroK8s configuration in the test instance to the created folder

```bash
multipass exec teste sudo microk8s config > $HOME/.kube/configs/teste-config
```

### Use in your session the configuration exported as default for use with Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/teste-config
```

### Install Kubectl

```bash
sudo snap install kubectl --classic
```

```bash
kubectl get no
```

```txt
NAME    STATUS     ROLES    AGE     VERSION
teste   NotReady   <none>   1m11s   v1.20.2-34+350770ed07a558

```

### Add an IP alias of the test instance to teste.info

```bash
multipass info teste | grep IPv4 | cut -f 2 -d ":" | sed -e 's/^[ \t]*//' | sed 's/$/     teste.info/' | sudo tee -a /etc/hosts
```

### Deploy a test application

```bash
kubectl apply -f https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/KUBERNETES/COMBO/example_combo_full.yaml
```

# MinIO

MinIO is a High Performance Object Storage, it is API compatible with Amazon S3 cloud storage service.

## Create a MinIO template

```bash
echo '#cloud-config
write_files:
 - path: /etc/environment
   content: |
     MINIO_ACCESS_KEY=minioadmin
     MINIO_SECRET_KEY=miniopassword
   append: true
 - path: /etc/rc.local
   owner: root:root
   permissions: '0777'
   content: |
     #!/bin/bash
     exec sudo minio server /opt/data &
     exit 0
   append: true
runcmd:
 - apt update --fix-missing
 - curl https://dl.min.io/server/minio/release/linux-amd64/minio --create-dirs -o /usr/local/bin/minio
 - curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/local/bin/mc
 - chmod +x /usr/local/bin/minio
 - chmod +x /usr/local/bin/mc
 - mkdir -p /opt/data/
 - chmod u+rxw /opt/data
 - export MINIO_ACCESS_KEY=minioadmin
 - export MINIO_SECRET_KEY=miniopassword
 - minio server /opt/data
 - mc config host add Velero http://localhost:9000 $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
 - mc mb -p /opt/data/velero' > cloud-config-minio.yaml
```

## Create a MinIO instance

```bash
multipass launch focal -n minio -c 2 -m 2G -d 5G --cloud-init cloud-config-minio.yaml
```

### Add an IP alias of the minio instance to minio.info

```bash
multipass info minio | grep IPv4 | cut -f 2 -d ":" | sed -e 's/^[ \t]*//' | sed 's/$/     minio.info/' | sudo tee -a /etc/hosts
```

### Create yaml for endpoint pointing to instance minio

```bash
echo 'apiVersion: v1
items:
- apiVersion: v1
  kind: Service
  metadata:
    name: minio
    namespace: teste
  spec:
    clusterIP: None
    ports:
    - name: minio
      port: 9000
      targetPort: 9000
- apiVersion: v1
  kind: Endpoints
  metadata:
    name: minio
    namespace: teste
  subsets:
  - addresses:
    - ip: MinioIP
    ports:
    - name: minio
      port: 9000
      protocol: TCP
kind: List
metadata: {}' > minio_endpoint.yaml
```

### Add IP of the minio instance to the endpoint yaml

```bash
for i in `multipass info minio | grep IPv4 | cut -f 2 -d ":" | sed -e 's/^[ \t]*//'` ; do sed -i s/MinioIP/$i/ minio_endpoint.yaml ; done
```

### Use in your session the configuration exported as default for use with Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/teste-config
```

### Create the endpoint pointing to the minio instance

```bash
kubectl apply -f minio_endpoint.yaml
```

# Velero

Velero is an open source tool to safely backup and restore, you can run with a cloud provider or on-premises.

## Install Velero

```bash
wget -c https://github.com/vmware-tanzu/velero/releases/download/v1.5.3/velero-v1.5.3-linux-amd64.tar.gz
tar -zxvf velero-v1.5.3-linux-amd64.tar.gz
cd velero-v1.5.3-linux-amd64/
sudo cp -raf velero /usr/local/sbin/
```

### Use in your session the configuration exported as default for use with Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/teste-config
```

## Create a file with MinIO credentials

```bash
echo '[default]
aws_access_key_id=minioadmin
aws_secret_access_key=miniopassword' > minio.credentials
```

### Install Velero in your cluster

```bash
velero install \
--backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.teste.svc.cluster.local:9000 \
--bucket velero \
--plugins velero/velero-plugin-for-aws:v1.0.0 \
--provider aws \
--secret-file ./minio.credentials
```

### View the status of your Velero deployment

```bash
kubectl logs deployment/velero -n velero
```

### Create a backup of the test namespace

```bash
velero backup create teste --include-namespaces teste
```

```txt
Backup request "teste" submitted successfully.
```

### View details of the backup created

```bash
velero backup describe teste
```

```txt
Name:         teste
Namespace:    velero
Labels:       velero.io/storage-location=default
Annotations:  velero.io/source-cluster-k8s-gitversion=v1.20.2-34+350770ed07a558
              velero.io/source-cluster-k8s-major-version=1
              velero.io/source-cluster-k8s-minor-version=20+

Phase:  Completed

Errors:    0
Warnings:  0

Namespaces:
  Included:  teste
  Excluded:  <none>

Resources:
  Included:        *
  Excluded:        <none>
  Cluster-scoped:  auto

Label selector:  <none>

Storage Location:  default

Velero-Native Snapshot PVs:  auto

TTL:  720h0m0s

Hooks:  <none>

Backup Format Version:  1.1.0

Started:    2021-03-08 15:53:02 -0300 -03
Completed:  2021-03-08 15:53:03 -0300 -03

Expiration:  2021-04-07 15:53:02 -0300 -03

Total items to be backed up:  25
Items backed up:              25

Velero-Native Snapshots: <none included>
```

### View created backup logs

```bash
velero backup logs teste
```

### See the velero bucket tree in the minio instance

```bash
multipass exec minio mc tree /opt/data/
```

```txt
/opt/data/
├─ .minio.sys
│  ├─ buckets
│  │  ├─ .minio.sys
│  │  │  └─ buckets
│  │  │     ├─ .bloomcycle.bin
│  │  │     ├─ .usage-cache.bin
│  │  │     ├─ .usage.json
│  │  │     └─ velero
│  │  │        └─ .usage-cache.bin
│  │  └─ velero
│  │     └─ backups
│  │        └─ teste
│  │           ├─ teste-csi-volumesnapshotcontents.json.gz
│  │           ├─ teste-csi-volumesnapshots.json.gz
│  │           ├─ teste-logs.gz
│  │           ├─ teste-podvolumebackups.json.gz
│  │           ├─ teste-resource-list.json.gz
│  │           ├─ teste-volumesnapshots.json.gz
│  │           ├─ teste.tar.gz
│  │           └─ velero-backup.json
│  ├─ config
│  │  └─ iam
│  ├─ multipart
│  └─ tmp
│     └─ 668c4447-b8b8-46fb-9a05-0dca0913093e
└─ velero
   └─ backups
      └─ teste
```

### View backup details in the minio instance

```
multipass exec minio mc ls /opt/data/velero/backups/teste
```

```txt
[2021-03-08 15:53:04 -03]    29B teste-csi-volumesnapshotcontents.json.gz
[2021-03-08 15:53:04 -03]    29B teste-csi-volumesnapshots.json.gz
[2021-03-08 15:53:03 -03] 3.3KiB teste-logs.gz
[2021-03-08 15:53:03 -03]    29B teste-podvolumebackups.json.gz
[2021-03-08 15:53:04 -03]   387B teste-resource-list.json.gz
[2021-03-08 15:53:04 -03]    29B teste-volumesnapshots.json.gz
[2021-03-08 15:53:03 -03]  11KiB teste.tar.gz
[2021-03-08 15:53:03 -03] 2.1KiB velero-backup.json
```

## Uninstalling Velero

```bash
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l component=velero
```

# Source:

**Ubuntu**: <https://ubuntu.com/>

**Multipass**: <https://multipass.run/>

**Cloud-init**: <https://cloud-init.io/>

**MicroK8s**: <https://microk8s.io/docs>

**MinIO**: <https://min.io/>

**Velero**: <https://velero.io/>

**Backup and Restore with Velero**: <https://documentation.suse.com/suse-caasp/4.5/html/caasp-admin/backup-and-restore-with-velero.html#_prerequisites_8>

**Backup and Restore EKS using Velero**: <https://www.eksworkshop.com/intermediate/280_backup-and-restore/>
