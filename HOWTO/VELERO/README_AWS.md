This POC (Proof of Concept) will use [EKSCTL](https://eksctl.io/), the official CLI for Amazon EKS to create a Kubernetes cluster, [MinIO Client](https://minio.github.io/mc/) to access Amazon S3 and [Velero](https://velero.io/) to backup the resources present in a [Kubernetes](https://kubernetes.io/) namespace to a bucket.

```bash
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
aws configure
```

# Create S3 bucket

```bash
export REGION=us-east-1
export PROFILE=<YOUR-PROFILE>
export ID=`aws sts get-caller-identity --query Account --output text --profile $PROFILE`
export ENVMODE=dev
```

```bash
aws s3api create-bucket \
  --bucket velero-bucket-$ID-eks-$ENVMODE \
  --region $REGION \
  --profile $PROFILE
```

## Create S3 policy

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

## Delete policy, ownership and access block to S3 bucket

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

# Set permissions for Velero

## Create IAM policy

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

## Create the IAM user

```bash
aws iam create-user \
  --user-name velero-user \
  --region $REGION \
  --profile $PROFILE
```

## Attach policies to give velero the necessary permissions

```bash
aws iam put-user-policy \
  --user-name velero-user \
  --policy-name velero-iam-policy \
  --policy-document file://velero-iam-policy.json \
  --region $REGION \
  --profile $PROFILE
```

## Attach policy to S3 bucket

```bash
aws s3api put-bucket-policy \
  --bucket velero-bucket-$ID-eks-$ENVMODE \
  --policy file://velero-s3-policy.json \
  --region $REGION \
  --profile $PROFILE
```

## Create an access key for the user

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

# Create ECR repository for Velero

## Creating a repository

```bash
aws ecr create-repository --repository-name velero/velero --region $REGION --profile $PROFILE
aws ecr create-repository --repository-name velero/velero-plugin-for-aws --region $REGION --profile $PROFILE
```

## Set life cycle policy

```bash
aws ecr put-lifecycle-policy --registry-id $ID --repository-name velero/velero --lifecycle-policy-text '{"rules":[{"rulePriority":10,"description":"Expire old images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":800},"action":{"type":"expire"}}]}' --region $REGION --profile $PROFILE
aws ecr put-lifecycle-policy --registry-id $ID --repository-name velero/velero-plugin-for-aws --lifecycle-policy-text '{"rules":[{"rulePriority":10,"description":"Expire old images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":800},"action":{"type":"expire"}}]}' --region $REGION --profile $PROFILE
```

## Retrieve an authentication token and authenticate your Docker client to your registry

```bash
aws ecr get-login-password --region $REGION --profile $PROFILE | sudo docker login --username AWS --password-stdin $ID.dkr.ecr.$REGION.amazonaws.com
```

```text
WARNING! Your password will be stored unencrypted in /root/snap/docker/796/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

## Pull original image for Velero AWS plugin

```bash
sudo docker pull velero/velero
sudo docker pull velero/velero-plugin-for-aws
```

## List local images

```bash
sudo docker images
```

```text
REPOSITORY                      TAG         IMAGE ID            CREATED         SIZE
velero/velero                   latest      236bc1f1c145        10 days ago     163MB
velero/velero-plugin-for-aws    latest      a7ec85c59439        3 weeks ago     105MB
```

## Create a TAG of the local image for the Registry

```bash
sudo docker image tag 236bc1f1c145 $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero:latest
sudo docker image tag a7ec85c59439 $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero-plugin-for-aws:latest
```

## Push the image to the Registry

```bash
sudo docker image push $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero:latest
sudo docker image push $ID.dkr.ecr.$REGION.amazonaws.com/velero/velero-plugin-for-aws:latest
```

# Install EKSCTL

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

## Checking AWS STS access to get role ARN for current session

```bash
aws sts get-caller-identity --query Account --output text --profile $PROFILE
```

## Creating an Amazon EKS cluster

```bash
eksctl create cluster \
 --name <YOUR-CLUSTER> \
 --version 1.19 \
 --region $REGION \
 --zones $REGION"a",$REGION"b",$REGION"c" \
 --profile $PROFILE
```

## Configure kubectl

To configure kubetcl, you need both [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

The following command will get the access credentials for your cluster and automatically
configure `kubectl`.

```bash
aws eks update-kubeconfig --name <YOUR-CLUSTER> --region $REGION --profile $PROFILE
```

# Install Velero

```bash
echo '[default]
aws_access_key_id=<AWS_SECRET_ACCESS_KEY>
aws_secret_access_key=<AWS_ACCESS_KEY_ID>' > velero-credentials.credential
```

```bash
aws eks list-clusters --region $REGION --profile $PROFILE
aws eks --region $REGION update-kubeconfig --name <YOUR-CLUSTER> --profile $PROFILE
kubectl config get-contexts
kubectl config use-context arn:aws:eks:$REGION:$ID:cluster/<YOUR-CLUSTER>
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

OR

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

OR

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

## Check that the velero is up and running

```bash
kubectl get deployment/velero -n velero
```

## Check that the secret has been created

```bash
kubectl get secret/velero -n velero
```

## View the status of your Velero deployment

```bash
kubectl logs deployment/velero -n velero
```

## Create a backup of the test namespace

```bash
velero backup create teste --include-namespaces teste
```

```txt
Backup request "teste" submitted successfully.
```

## View details of the backup created

### List backups

```bash
velero backup get
```

### Describe backup

```bash
velero backup describe teste
```

### Retrieve backup logs

```bash
velero backup logs teste
```

## Restore a backup of the test namespace

```bash
velero restore create --from-backup teste
```

## Create schedule template

### Create a backup every 1 hour of the teste namespace

```bash
velero schedule create teste --schedule="0 */1 * * *" --include-namespaces teste
```

### Create a hourly backup of the teste namespace with the @every notation

```bash
velero schedule create teste-hourly --schedule="@every 1h" --include-namespaces teste
```

### Create a daily backup of the teste namespace with the @every notation

```bash
velero schedule create teste-daily --schedule="@every 24h" --include-namespaces teste
```

### Create a weekly backup of the teste namespace with the @every notation, each living for 90 days (2160 hours)

```bash
velero schedule create teste-weekly --schedule="@every 168h" --include-namespaces teste --ttl 2160h0m0s
```

## View details of the backup schedule created

### List backup schedule

```bash
velero schedule get
```

```text
NAME             STATUS    CREATED                         SCHEDULE      BACKUP TTL   LAST BACKUP   SELECTOR
teste-daily      Enabled   2021-04-12 17:17:32 -0300 -03   @every 24h    720h0m0s      1m ago       <none>
teste-hourly     Enabled   2021-04-12 17:14:33 -0300 -03   @every 1h     720h0m0s      1m ago       <none>
teste-weekly     Enabled   2021-04-12 17:18:03 -0300 -03   @every 168h   2160h0m0s     1m ago       <none>

```

### Describe backup schedule

#### Hourly

```bash
velero schedule describe teste-hourly
```

#### Daily

```bash
velero schedule describe teste-daily
```

#### Weekly

```bash
velero schedule describe teste-weekly
```

### Retrieve backup schedule logs

#### Hourly

```bash
velero backup get | grep teste-hourly-<TIMESTAMP>
velero backp logs teste-hourly-<TIMESTAMP>
```

#### Daily

```bash
velero backup get | grep teste-daily-<TIMESTAMP>
velero backup logs este-daily-<TIMESTAMP>
```

#### Weekly

```bash
velero backup get | grep teste-weekly-<TIMESTAMP>
velero backup logs teste-weekly-<TIMESTAMP>
```

## Restore a backup schedule of the test namespace

```bash
velero restore create --from-schedule <SCHEDULE_NAME>
velero restore create <RESTORE_NAME> --from-schedule <SCHEDULE_NAME>
```

#### Hourly

```bash
velero restore create --from-schedule teste-hourly-<TIMESTAMP>
velero restore create teste-hourly-<TIMESTAMP> --from-schedule teste-hourly-<TIMESTAMP>
```

#### Daily

```bash
velero restore create --from-schedule teste-daily-<TIMESTAMP>
velero restore create teste-daily-<TIMESTAMP> --from-schedule teste-daily-<TIMESTAMP>
```

#### Weekly

```bash
velero restore create --from-schedule teste-weekly-<TIMESTAMP>
velero restore create teste-weekly-<TIMESTAMP> --from-schedule teste-weekly-<TIMESTAMP>
```

# List objects in bucket using aws-cli

```bash
aws s3api list-objects --bucket velero-bucket-$ID-eks-dev --query 'Contents[].{Key: Key, Size: Size}' --region $REGION --profile $PROFILE
```

# List objects in bucket using MC

## Install MC

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/local/bin/mc
chmod +x /usr/local/bin/mc
```

## Get your AccessKeyID and SecretAccessKey

```bash
mc alias set s3 https://s3.amazonaws.com <AWS_SECRET_ACCESS_KEY> <AWS_ACCESS_KEY_ID> --api S3v4
```

## Lsts directories in a tree format

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

## Lists files in bucket

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

# Uninstalling Velero

```bash
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l component=velero
```

OR

```bash
helm uninstall velero --namespace velero
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l app.kubernetes.io/name=velero
```

# Delete Amazon EKS cluster

```bash
eksctl delete cluster --name <YOUR-CLUSTER> --region $REGION --profile $PROFILE
```

# Source:

**MinIO**: <https://min.io/>

**Velero**: <https://velero.io/>

**MinIO Client Complete Guide**: <https://github.com/minio/mc/blob/master/docs/minio-client-complete-guide.md>

**Backup and Restore with Velero**: <https://documentation.suse.com/suse-caasp/4.5/html/caasp-admin/backup-and-restore-with-velero.html#_prerequisites_8>

**Backup and Restore EKS using Velero**: <https://www.eksworkshop.com/intermediate/280_backup-and-restore/>

**Your AWS account identifiers**: <https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html>

**Installing or upgrading eksctl**: <https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html>

**Creating an Amazon EKS cluster**: <https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html>
