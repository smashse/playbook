# RBAC

## Microk8s

```bash
echo '#cloud-config
runcmd:
 - apt update --fix-missing
 - snap refresh
 - snap install microk8s --classic
 - microk8s status --wait-ready
 - microk8s enable dns ingress' > cloud-config-microk8s.yaml
 ```

```bash
multipass launch focal -n microk8s -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
```

```bash
sudo mkdir -p $HOME/.kube/configs
```

```bash
multipass exec microk8s sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

```bash
chmod 0600 $KUBECONFIG
```

```bash
kubectl config get-contexts
```

```text
CURRENT   NAME       CLUSTER            AUTHINFO   NAMESPACE
*         microk8s   microk8s-cluster   admin 
```

```bash
kubectl config view
```

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://<YOUR_IP>:16443
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

```bash
kubectl config view | sed "s/DATA+OMITTED/\${CA}/" | sed "s/admin/user-\${USER_NAME}/"  | sed "s/REDACTED/\${TOKEN}/"
```

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CA}
    server: https://<YOUR_IP>:16443
  name: microk8s-cluster
contexts:
- context:
    cluster: microk8s-cluster
    user: user-${USER_NAME}
  name: microk8s
current-context: microk8s
kind: Config
preferences: {}
users:
- name: user-${USER_NAME}
  user:
    token: ${TOKEN}
```

## Create individual Kubeconfig's

```bash
# Create service accounts with the users below.
echo 'fulano.user
sicrano.user
beltrano.user' > users.txt &&
for i in `cat users.txt` ; do kubectl create sa $i ; done &&
# Get access tokens for created service accounts.
sleep 10s ; for i in `cat users.txt` ; do kubectl get sa/$i -o jsonpath="{.secrets[0].name}" | { tr -d '\n'; echo; } >> tokens.txt ; done &&
# Use tokens to obtain access credentials and create individual cluster configuration files.
for i in `cat tokens.txt` ;
do export TOKEN_NAME=$i &&
CA=$(kubectl get secret/$TOKEN_NAME -o jsonpath='{.data.ca\.crt}') &&
TOKEN=$(kubectl get secret/$TOKEN_NAME -o jsonpath='{.data.token}' | base64 --decode) &&
USER_NAME=$(echo $TOKEN_NAME | cut -f 1 -d -) &&
echo "apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CA}
    server: https://<YOUR_IP>:16443
  name: microk8s-cluster
contexts:
- context:
    cluster: microk8s-cluster
    user: user-${USER_NAME}
  name: microk8s
current-context: microk8s
kind: Config
preferences: {}
users:
- name: user-${USER_NAME}
  user:
    token: ${TOKEN}" > config-$USER_NAME ;
done
```

## Granting access for service accounts as admin to the cluster

This example generates a yaml for each user, in it we have the "Namespace", "ServiceAccount", "ClusterRole" and "ClusterRoleBinding".

- **Namespace:** _Mechanism for isolating cluster resource groups._

- **ServiceAccount:** _Provides an identity to access cluster resources._

- **ClusterRole:** _Provides access and permissions to access resources in the cluster._

- **ClusterRoleBinding:** _Provides the binding between ServiceAccount(the identity) and ClusterRole(the accesses and permissions)._

```bash
for i in `cat users.txt` ;
do export USER_NAME=$i &&
echo "apiVersion: v1
items:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: default
  - apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${USER_NAME}
      namespace: default
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: ${USER_NAME}
      namespace: default
    rules:
      - apiGroups: ['*']
        resources: ['*']
        verbs: ['*']
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: ${USER_NAME}
      namespace: default
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: ${USER_NAME}
    subjects:
      - kind: ServiceAccount
        name: ${USER_NAME}
        namespace: default
kind: List
metadata: {}" > microk8s-rbac-admin-$USER_NAME.yaml;
done
```

```bash
for i in `cat users.txt` ; do kubectl apply -f microk8s-rbac-admin-$i.yaml ; done
```

In this example, users have full access in their ClusterRole, if we wanted a rule for the "deployments" resource.

```bash
kubectl api-resources -o wide | grep "^deployments"
```

```text
NAME                  SHORTNAMES   APIVERSION   NAMESPACED   KIND                 VERBS
deployments           deploy       apps/v1      true         Deployment           [create delete deletecollection get list patch update watch]
```

The rule would be like this.

```yaml
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: ${USER_NAME}
      namespace: default
    rules:
      - apiGroups: ['apps']
        resources: ['deployments']
        verbs: ['create', 'delete', 'get', 'list']
```

**Sources:**

<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>

<https://www.redhat.com/en/topics/containers/what-kubernetes-role-based-access-control-rbac>

<https://learnk8s.io/rbac-kubernetes>
