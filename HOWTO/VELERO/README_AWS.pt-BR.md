*Read this in other languages: [en-US](README_AWS.md), [pt-BR](README_AWS.pt-BR.md)*

Esta POC (Prova de Conceito) usará o [EKSCTL](https://eksctl.io/), a CLI oficial para o Amazon EKS para criar um cluster Kubernetes, o [MinIO Client](https://minio.github.io/mc/) para acessar o Amazon S3 e o [Velero](https://velero.io/) para fazer backup dos recursos presentes em um namespace [Kubernetes](https://kubernetes.io/) para um bucket.

```bash
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
aws configure
```

# Crie um bucket S3

```bash
export REGION=us-east-1
export PROFILE=<SEU-PERFIL>
export ID=`aws sts get-caller-identity --query Account --output text --profile $PROFILE`
export ENVMODE=dev
```

```bash
aws s3api create-bucket \
  --bucket velero-bucket-$ID-eks-$ENVMODE \
  --region $REGION \
  --profile $PROFILE
```

## Crie uma política S3

```bash
cat > velero-s3-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$ID:user/velero-user"
      },
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::velero-bucket-$ID-eks-$ENVMODE"
    },
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$ID:user/velero-user"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::velero-bucket-$ID-eks-$ENVMODE/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": ["aws:kms", "AES256"]
        }
      }
    },
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$ID:user/velero-user"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::velero-bucket-$ID-eks-$ENVMODE/*",
      "Condition": {
        "Null": {
          "s3:x-amz-server-side-encryption": "true"
        }
      }
    }
  ]
}
EOF
```

## Exclua a política, o controle de propriedade e o bloqueio de acesso ao bucket S3

```bash
aws s3api delete-bucket-policy \
  --bucket velero-bucket-$ID-eks-$ENVMODE \
  --region $REGION \
  --profile $PROFILE
```

```bash
aws s3api delete-bucket-ownership-controls \
  --bucket velero-bucket-$ID-eks-$ENVMODE \
  --region $REGION \
  --profile $PROFILE
```

```bash
aws s3api delete-public-access-block \
  --bucket velero-bucket-$ID-eks-$ENVMODE \
  --region $REGION \
  --profile $PROFILE
```

# Defina permissões para o Velero

## Crie uma política IAM

```bash
cat > velero-iam-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::velero-bucket-$ID-eks-$ENVMODE/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::velero-bucket-$ID-eks-$ENVMODE"
            ]
        }
    ]
}
EOF
```

## Crie o usuário IAM

```bash
aws iam create-user \
  --user-name velero-user \
  --region $REGION \
  --profile $PROFILE
```

## Anexe políticas para dar ao velero as permissões necessárias

```bash
aws iam put-user-policy \
  --user-name velero-user \
  --policy-name velero-iam-policy \
  --policy-document file://velero-iam-policy.json \
  --region $REGION \
  --profile $PROFILE
```

## Anexe a política ao bucket S3

```bash
aws s3api put-bucket-policy \
  --bucket velero-bucket-$ID-eks-$ENVMODE \
  --policy file://velero-s3-policy.json \
  --region $REGION \
  --profile $PROFILE
```

## Crie uma chave de acesso para o usuário

```bash
aws iam create-access-key \
  --user-name velero-user \
  --region $REGION \
  --profile $PROFILE
```

```text
{
    "AccessKey": {
        "UserName": "velero-user",
        "AccessKeyId": "<AWS_ACCESS_KEY_ID>",
        "Status": "Active",
        "SecretAccessKey": "<AWS_SECRET_ACCESS_KEY>",
        "CreateDate": "2021-04-10T14:39:14+00:00"
    }
}
```

# Crie um repositório ECR para o Velero

## Criando um repositório

```bash
aws ecr create-repository --repository-name velero/velero --region $REGION --profile $PROFILE
aws ecr create-repository --repository-name velero/velero-plugin-for-aws --region $REGION --profile $PROFILE
```

## Defina a política de ciclo de vida

```bash
aws ecr put-lifecycle-policy --registry-id $ID --repository-name velero/velero --lifecycle-policy-text '{"rules":[{"rulePriority":10,"description":"Expire old images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":800},"action":{"type":"expire"}}]}' --region $REGION --profile $PROFILE
aws ecr put-lifecycle-policy --registry-id $ID --repository-name velero/velero-plugin-for-aws --lifecycle-policy-text '{"rules":[{"rulePriority":10,"description":"Expire old images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":800},"action":{"type":"expire"}}]}' --region $REGION --profile $PROFILE
```

## Recupere um token de autenticação e autentique seu cliente Docker em seu registro

```bash
aws ecr get-login-password --region $REGION --profile $PROFILE | sudo docker login --username AWS --password-stdin $ID.dkr.ecr.$REGION.amazonaws.com
```

```text
WARNING! Your password will be stored unencrypted in /root/snap/docker/796/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

## Baixe a imagem original do plugin Velero AWS

```bash
sudo docker pull velero/velero
sudo docker pull velero/velero-plugin-for-aws
```

## Liste as imagens locais

```bash
sudo docker images
```

```text
REPOSITORY                      TAG         IMAGE ID            CREATED         SIZE
velero/velero                   latest      236bc1f1c145        10 days ago     163MB
velero/velero-plugin-for-aws    latest      a7ec85c59439        3 weeks ago     105MB
```

## Crie uma TAG da imagem local para o Registry

```bash
sudo docker image tag 236bc1f1c145 $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero:latest
sudo docker image tag a7ec85c59439 $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero-plugin-for-aws:latest
```

## Envie a imagem para o Registry

```bash
sudo docker image push $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero:latest
sudo docker image push $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero-plugin-for-aws:latest
```

# Instale o EKSCTL

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

## Verificando o acesso do AWS STS para obter o ARN da role para a sessão atual

```bash
aws sts get-caller-identity --query Account --output text --profile $PROFILE
```

## Criando um cluster Amazon EKS

```bash
eksctl create cluster \
 --name <SEU-CLUSTER> \
 --version 1.19 \
 --region $REGION \
 --zones $REGION"a",$REGION"b",$REGION"c" \
 --profile $PROFILE
```

## Configure o kubectl

Para configurar o kubetcl, você precisa do [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) e do [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

O comando a seguir obterá as credenciais de acesso para o seu cluster e configurará automaticamente
o `kubectl`.

```bash
aws eks update-kubeconfig --name <SEU-CLUSTER> --region $REGION --profile $PROFILE
```

# Instale o Velero

```bash
echo '[default]
aws_access_key_id=<AWS_SECRET_ACCESS_KEY>
aws_secret_access_key=<AWS_ACCESS_KEY_ID>' > velero-credentials.credential
```

```bash
aws eks list-clusters --region $REGION --profile $PROFILE
aws eks --region $REGION update-kubeconfig --name <SEU-CLUSTER> --profile $PROFILE
kubectl config get-contexts
kubectl config use-context arn:aws:eks:$REGION:$ID:cluster/<SEU-CLUSTER>
kubectl config current-context
```

```bash
wget -c https://github.com/vmware-tanzu/velero/releases/download/v1.5.4/velero-v1.5.4-linux-amd64.tar.gz
tar -zxvf velero-v1.5.4-linux-amd64.tar.gz
cd velero-v1.5.4-linux-amd64/
sudo cp -raf velero /usr/local/sbin/
```

```bash
velero install \
--backup-location-config region=$REGION \
--bucket velero-bucket-$ID-eks-$ENVMODE \
--image $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero:latest \
--plugins $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero-plugin-for-aws:latest \
--provider aws \
--secret-file ./velero-credentials.credential \
--snapshot-location-config region=$REGION \
--add_dir_header \
--prefix $ENVMODE
```

OU

```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
```

```bash
helm install velero vmware-tanzu/velero \
--namespace velero \
--create-namespace \
--set-file credentials.secretContents.cloud=./velero-credentials.credential \
--set configuration.provider=aws \
--set configuration.backupStorageLocation.name=default \
--set configuration.backupStorageLocation.bucket=velero-bucket-$ID-eks-$ENVMODE \
--set configuration.backupStorageLocation.prefix=$ENVMODE \
--set configuration.backupStorageLocation.config.region=$REGION \
--set configuration.volumeSnapshotLocation.name=default \
--set configuration.volumeSnapshotLocation.config.region=$REGION \
--set image.repository=$ID.dkr.ecr.$REGION.amazonaws.com/velero/velero \
--set image.tag=latest \
--set image.pullPolicy=IfNotPresent \
--set initContainers[0].name=velero-plugin-for-aws \
--set initContainers[0].image=$ID.dkr.ecr.$REGION.amazonaws.com/velero/velero-plugin-for-aws:latest \
--set initContainers[0].imagePullPolicy=IfNotPresent \
--set initContainers[0].volumeMounts[0].mountPath=/target \
--set initContainers[0].volumeMounts[0].name=plugins
```

OU

```bash
cat > velero-values.yaml <<EOF
configuration:
  backupStorageLocation:
    bucket: velero-bucket-$ID-eks-$ENVMODE
    config:
      region: $REGION
    name: default
    prefix: $ENVMODE
  provider: aws
  volumeSnapshotLocation:
    config:
      region: $REGION
    name: default
image:
  pullPolicy: IfNotPresent
  repository: $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero
  tag: latest
initContainers:
  - image: $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero-plugin-for-aws:latest
    imagePullPolicy: IfNotPresent
    name: velero-plugin-for-aws
    volumeMounts:
      - mountPath: /target
        name: plugins
EOF
```

```bash
helm install velero vmware-tanzu/velero \
--namespace velero \
--create-namespace \
--set-file credentials.secretContents.cloud=./velero-credentials.credential \
-f velero-values.yaml
```

## Verifique se o velero está instalado e em execução

```bash
kubectl get deployment/velero -n velero
```

## Verifique se o secret foi criado

```bash
kubectl get secret/velero -n velero
```

## Veja o status da sua implantação do Velero

```bash
kubectl logs deployment/velero -n velero
```

## Crie um backup do namespace de teste

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
teste-daily      Enabled   2021-04-12 17:17:32 -0300 -03   @every 24h    720h0m0s      1m ago       <none>
teste-hourly     Enabled   2021-04-12 17:14:33 -0300 -03   @every 1h     720h0m0s      1m ago       <none>
teste-weekly     Enabled   2021-04-12 17:18:03 -0300 -03   @every 168h   2160h0m0s     1m ago       <none>

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

# Liste objetos no bucket usando aws-cli

```bash
aws s3api list-objects --bucket velero-bucket-$ID-eks-dev --query 'Contents[].{Key: Key, Size: Size}' --region $REGION --profile $PROFILE
```

# Liste objetos no bucket usando MC

## Instale o MC

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/local/bin/mc
chmod +x /usr/local/bin/mc
```

## Obtenha seu AccessKeyID e SecretAccessKey

```bash
mc alias set s3 https://s3.amazonaws.com <AWS_SECRET_ACCESS_KEY> <AWS_ACCESS_KEY_ID> --api S3v4
```

## Lista diretórios em formato de árvore

```bash
mc tree s3/velero-bucket-$ID-eks-dev
```

```text
s3/velero-bucket-$ID-eks-dev
└─ dev
   └─ backups
      ├─ teste-daily-20210412201732
      ├─ teste-hourly-20210412201433
      ├─ teste-weekly-20210412201803
      └─ teste
```

## Lista arquivos no bucket

```bash
mc ls s3/velero-bucket-$ID-eks-dev --recursive --summarize
```

```text
[2021-04-12 17:17:40 -03]    29B null v1 PUT dev/backups/teste-daily-20210412201732/teste-daily-20210412201732-csi-volumesnapshotcontents.json.gz
[2021-04-12 17:17:40 -03]    29B null v1 PUT dev/backups/teste-daily-20210412201732/teste-daily-20210412201732-csi-volumesnapshots.json.gz
[2021-04-12 17:17:40 -03] 3.4KiB null v1 PUT dev/backups/teste-daily-20210412201732/teste-daily-20210412201732-logs.gz
[2021-04-12 17:17:40 -03]    29B null v1 PUT dev/backups/teste-daily-20210412201732/teste-daily-20210412201732-podvolumebackups.json.gz
[2021-04-12 17:17:40 -03]   160B null v1 PUT dev/backups/teste-daily-20210412201732/teste-daily-20210412201732-resource-list.json.gz
[2021-04-12 17:17:40 -03]    29B null v1 PUT dev/backups/teste-daily-20210412201732/teste-daily-20210412201732-volumesnapshots.json.gz
[2021-04-12 17:17:40 -03] 4.4KiB null v1 PUT dev/backups/teste-daily-20210412201732/teste-daily-20210412201732.tar.gz
[2021-04-12 17:17:40 -03] 1.2KiB null v1 PUT dev/backups/teste-daily-20210412201732/velero-backup.json
[2021-04-12 17:14:41 -03]    29B null v1 PUT dev/backups/teste-hourly-20210412201433/teste-hourly-20210412201433-csi-volumesnapshotcontents.json.gz
[2021-04-12 17:14:41 -03]    29B null v1 PUT dev/backups/teste-hourly-20210412201433/teste-hourly-20210412201433-csi-volumesnapshots.json.gz
[2021-04-12 17:14:40 -03] 3.4KiB null v1 PUT dev/backups/teste-hourly-20210412201433/teste-hourly-20210412201433-logs.gz
[2021-04-12 17:14:41 -03]    29B null v1 PUT dev/backups/teste-hourly-20210412201433/teste-hourly-20210412201433-podvolumebackups.json.gz
[2021-04-12 17:14:41 -03]   160B null v1 PUT dev/backups/teste-hourly-20210412201433/teste-hourly-20210412201433-resource-list.json.gz
[2021-04-12 17:14:41 -03]    29B null v1 PUT dev/backups/teste-hourly-20210412201433/teste-hourly-20210412201433-volumesnapshots.json.gz
[2021-04-12 17:14:41 -03] 4.4KiB null v1 PUT dev/backups/teste-hourly-20210412201433/teste-hourly-20210412201433.tar.gz
[2021-04-12 17:14:40 -03] 1.2KiB null v1 PUT dev/backups/teste-hourly-20210412201433/velero-backup.json
[2021-04-12 17:18:11 -03]    29B null v1 PUT dev/backups/teste-weekly-20210412201803/teste-weekly-20210412201803-csi-volumesnapshotcontents.json.gz
[2021-04-12 17:18:11 -03]    29B null v1 PUT dev/backups/teste-weekly-20210412201803/teste-weekly-20210412201803-csi-volumesnapshots.json.gz
[2021-04-12 17:18:10 -03] 3.4KiB null v1 PUT dev/backups/teste-weekly-20210412201803/teste-weekly-20210412201803-logs.gz
[2021-04-12 17:18:11 -03]    29B null v1 PUT dev/backups/teste-weekly-20210412201803/teste-weekly-20210412201803-podvolumebackups.json.gz
[2021-04-12 17:18:11 -03]   160B null v1 PUT dev/backups/teste-weekly-20210412201803/teste-weekly-20210412201803-resource-list.json.gz
[2021-04-12 17:18:10 -03]    29B null v1 PUT dev/backups/teste-weekly-20210412201803/teste-weekly-20210412201803-volumesnapshots.json.gz
[2021-04-12 17:18:10 -03] 4.4KiB null v1 PUT dev/backups/teste-weekly-20210412201803/teste-weekly-20210412201803.tar.gz
[2021-04-12 17:18:10 -03] 1.2KiB null v1 PUT dev/backups/teste-weekly-20210412201803/velero-backup.json
[2021-04-12 17:07:11 -03]    29B null v1 PUT dev/backups/teste/teste-csi-volumesnapshotcontents.json.gz
[2021-04-12 17:07:11 -03]    29B null v1 PUT dev/backups/teste/teste-csi-volumesnapshots.json.gz
[2021-04-12 17:07:11 -03] 3.4KiB null v1 PUT dev/backups/teste/teste-logs.gz
[2021-04-12 17:07:11 -03]    29B null v1 PUT dev/backups/teste/teste-podvolumebackups.json.gz
[2021-04-12 17:07:11 -03]   160B null v1 PUT dev/backups/teste/teste-resource-list.json.gz
[2021-04-12 17:07:11 -03]    29B null v1 PUT dev/backups/teste/teste-volumesnapshots.json.gz
[2021-04-12 17:07:11 -03] 4.5KiB null v1 PUT dev/backups/teste/teste.tar.gz
[2021-04-12 17:07:11 -03] 1.2KiB null v1 PUT dev/backups/teste/velero-backup.json

Total Size: 1.3 MiB
Total Objects: 32
```

# Desinstalando o Velero

```bash
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l component=velero
```

OU

```bash
helm uninstall velero --namespace velero
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l app.kubernetes.io/name=velero
```

# Exclua o cluster Amazon EKS

```bash
eksctl delete cluster --name <SEU-CLUSTER> --region $REGION --profile $PROFILE
```

# Fonte:

**MinIO**: <https://min.io/>

**Velero**: <https://velero.io/>

**Guia Completo do MinIO Client**: <https://github.com/minio/mc/blob/master/docs/minio-client-complete-guide.md>

**Backup e Restauração com Velero**: <https://documentation.suse.com/suse-caasp/4.5/html/caasp-admin/backup-and-restore-with-velero.html#_prerequisites_8>

**Backup e Restauração do EKS usando Velero**: <https://www.eksworkshop.com/intermediate/280_backup-and-restore/>

**Seus identificadores de conta AWS**: <https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html>

**Instalando ou atualizando o eksctl**: <https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html>

**Criando um cluster Amazon EKS**: <https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html>
