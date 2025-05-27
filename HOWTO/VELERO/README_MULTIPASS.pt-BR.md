*Read this in other languages: [en-US](README_MULTIPASS.md), [pt-BR](README_MULTIPASS.pt-BR.md)*

Esta POC (Prova de Conceito) usará o [Ubuntu](https://ubuntu.com/) como SO base, [Multipass](https://multipass.run/), [MicroK8s](https://microk8s.io/), [MinIO](https://min.io/) e [Velero](https://velero.io/) para fazer backup dos recursos presentes em um namespace [Kubernetes](https://kubernetes.io/) para um bucket.

# Multipass

Multipass é uma mini-nuvem em sua estação de trabalho usando hipervisores nativos de todas as plataformas suportadas (Windows, macOS e Linux). O Multipass pode iniciar e executar máquinas virtuais e configurá-las com [cloud-init](https://cloud-init.io/) como uma nuvem pública.

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
 - microk8s enable dns ingress metrics-server prometheus' > cloud-config-microk8s.yaml
```

## Crie uma instância MicroK8s

```bash
multipass launch focal -n teste -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
```

## Exporte a configuração atual do MicroK8s para uso com o Kubectl

### Crie a pasta para armazenar a configuração do cluster Kubernetes na instância de teste

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Exporte a configuração do MicroK8s na instância de teste para a pasta criada

```bash
multipass exec teste sudo microk8s config > $HOME/.kube/configs/teste-config
```

### Use em sua sessão a configuração exportada como padrão para uso com o Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/teste-config
```

### Instale o Kubectl

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

### Adicione um alias de IP da instância de teste para teste.info

```bash
multipass info teste | grep IPv4 | cut -f 2 -d ":" | sed -e 's/^[ \t]*//' | sed 's/$/     teste.info/' | sudo tee -a /etc/hosts
```

### Implante uma aplicação de teste

```bash
kubectl apply -f https://raw.githubusercontent.com/smashse/playbook/master/HOWTO/KUBERNETES/COMBO/example_combo_full.yaml
```

# MinIO

MinIO é um armazenamento de objetos de alto desempenho, compatível com a API do serviço de armazenamento em nuvem Amazon S3.

## Crie um template MinIO

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

## Crie uma instância MinIO

```bash
multipass launch focal -n minio -c 2 -m 2G -d 5G --cloud-init cloud-config-minio.yaml
```

### Adicione um alias de IP da instância minio para minio.info

```bash
multipass info minio | grep IPv4 | cut -f 2 -d ":" | sed -e 's/^[ \t]*//' | sed 's/$/     minio.info/' | sudo tee -a /etc/hosts
```

### Crie um yaml para o endpoint apontando para a instância minio

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

### Adicione o IP da instância minio ao yaml do endpoint

```bash
for i in `multipass info minio | grep IPv4 | cut -f 2 -d ":" | sed -e 's/^[ \t]*//'` ; do sed -i s/MinioIP/$i/ minio_endpoint.yaml ; done
```

### Use em sua sessão a configuração exportada como padrão para uso com o Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/teste-config
```

### Crie o endpoint apontando para a instância minio

```bash
kubectl apply -f minio_endpoint.yaml
```

# Velero

Velero é uma ferramenta de código aberto para fazer backup e restauração com segurança, você pode executá-lo com um provedor de nuvem ou on-premises.

## Instale o Velero

```bash
wget -c https://github.com/vmware-tanzu/velero/releases/download/v1.5.4/velero-v1.5.4-linux-amd64.tar.gz
tar -zxvf velero-v1.5.4-linux-amd64.tar.gz
cd velero-v1.5.4-linux-amd64/
sudo cp -raf velero /usr/local/sbin/
```

### Use em sua sessão a configuração exportada como padrão para uso com o Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/teste-config
```

## Crie um arquivo com as credenciais do MinIO

```bash
echo '[default]
aws_access_key_id=minioadmin
aws_secret_access_key=miniopassword' > minio.credentials
```

### Instale o Velero em seu cluster

```bash
velero install \
--backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.teste.svc.cluster.local:9000 \
--bucket velero \
--plugins velero/velero-plugin-for-aws:v1.0.0 \
--provider aws \
--secret-file ./minio.credentials
```

### Veja o status da sua implantação do Velero

```bash
kubectl logs deployment/velero -n velero
```

### Crie um backup do namespace de teste

```bash
velero backup create teste --include-namespaces teste
```

```txt
Backup request "teste" submitted successfully.
```

## Veja os detalhes do backup criado

### Listar backups

```bash
velero backup get
```

### Descrever backup

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

Started:    2021-05-05 15:15:15 -0300 -03
Completed:  2021-05-05 15:15:15 -0300 -03

Expiration:  2021-05-04 15:15:15 -0300 -03

Total items to be backed up:  25
Items backed up:              25

Velero-Native Snapshots: <none included>
```

### Recuperar logs de backup

```bash
velero backup logs teste
```

## Restaure um backup do namespace de teste

```bash
velero restore create --from-backup teste
```

## Crie um template de agendamento

### Crie um backup a cada 1 hora do namespace de teste

```bash
velero schedule create teste --schedule="0 */1 * * *" --include-namespaces teste
```

### Crie um backup de hora em hora do namespace de teste com a notação @every

```bash
velero schedule create teste-hourly --schedule="@every 1h" --include-namespaces teste
```

### Crie um backup diário do namespace de teste com a notação @every

```bash
velero schedule create teste-daily --schedule="@every 24h" --include-namespaces teste
```

### Crie um backup semanal do namespace de teste com a notação @every, cada um durando 90 dias (2160 horas)

```bash
velero schedule create teste-weekly --schedule="@every 168h" --include-namespaces teste --ttl 2160h0m0s
```

## Veja os detalhes do agendamento de backup criado

### Listar agendamento de backup

```bash
velero schedule get
```

```text
NAME             STATUS    CREATED                         SCHEDULE      BACKUP TTL   LAST BACKUP   SELECTOR
teste-daily      Enabled   2021-05-05 15:15:15 -0300 -03   @every 24h    720h0m0s      1m ago       <none>
teste-hourly     Enabled   2021-05-05 15:15:15 -0300 -03   @every 1h     720h0m0s      1m ago       <none>
teste-weekly     Enabled   2021-05-05 15:15:15 -0300 -03   @every 168h   2160h0m0s     1m ago       <none>

```

### Descrever agendamento de backup

#### De hora em hora

```bash
velero schedule describe teste-hourly
```

#### Diário

```bash
velero schedule describe teste-daily
```

#### Semanal

```bash
velero schedule describe teste-weekly
```

### Recuperar logs de agendamento de backup

#### De hora em hora

```bash
velero backup get | grep teste-hourly-<TIMESTAMP>
velero backp logs teste-hourly-<TIMESTAMP>
```

#### Diário

```bash
velero backup get | grep teste-daily-<TIMESTAMP>
velero backup logs este-daily-<TIMESTAMP>
```

#### Semanal

```bash
velero backup get | grep teste-weekly-<TIMESTAMP>
velero backup logs teste-weekly-<TIMESTAMP>
```

## Restaure um agendamento de backup do namespace de teste

```bash
velero restore create --from-schedule <NOME_AGENDAMENTO>
velero restore create <NOME_RESTAURACAO> --from-schedule <NOME_AGENDAMENTO>
```

#### De hora em hora

```bash
velero restore create --from-schedule teste-hourly-<TIMESTAMP>
velero restore create teste-hourly-<TIMESTAMP> --from-schedule teste-hourly-<TIMESTAMP>
```

#### Diário

```bash
velero restore create --from-schedule teste-daily-<TIMESTAMP>
velero restore create teste-daily-<TIMESTAMP> --from-schedule teste-daily-<TIMESTAMP>
```

#### Semanal

```bash
velero restore create --from-schedule teste-weekly-<TIMESTAMP>
velero restore create teste-weekly-<TIMESTAMP> --from-schedule teste-weekly-<TIMESTAMP>
```

### Veja a árvore do bucket velero na instância minio

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

### Veja os detalhes do backup na instância minio

```
multipass exec minio mc ls /opt/data/velero/backups/teste
```

```txt
[2021-05-05 15:15:15 -03]    29B teste-csi-volumesnapshotcontents.json.gz
[2021-05-05 15:15:15 -03]    29B teste-csi-volumesnapshots.json.gz
[2021-05-05 15:15:15 -03] 3.3KiB teste-logs.gz
[2021-05-05 15:15:15 -03]    29B teste-podvolumebackups.json.gz
[2021-05-05 15:15:15 -03]   387B teste-resource-list.json.gz
[2021-05-05 15:15:15 -03]    29B teste-volumesnapshots.json.gz
[2021-05-05 15:15:15 -03]  11KiB teste.tar.gz
[2021-05-05 15:15:15 -03] 2.1KiB velero-backup.json
```

## Desinstalando o Velero

```bash
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l component=velero
```

# Fonte:

**Ubuntu**: <https://ubuntu.com/>

**Multipass**: <https://multipass.run/>

**Cloud-init**: <https://cloud-init.io/>

**MicroK8s**: <https://microk8s.io/docs>

**MinIO**: <https://min.io/>

**Velero**: <https://velero.io/>

**Guia Completo do MinIO Client**: <https://github.com/minio/mc/blob/master/docs/minio-client-complete-guide.md>

**Backup e Restauração com Velero**: <https://documentation.suse.com/suse-caasp/4.5/html/caasp-admin/backup-and-restore-with-velero.html#_prerequisites_8>

**Backup e Restauração do EKS usando Velero**: <https://www.eksworkshop.com/intermediate/280_backup-and-restore/>
