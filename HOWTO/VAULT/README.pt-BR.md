*Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)*

# Requisitos para esta POC

Nesta POC, usaremos o Multipass para criar instâncias para instalar o Vault e o Microk8s, estabelecendo então o servidor Vault como um gerenciador de credenciais para o cluster Kubernetes provisionado com o Microk8s.

## Instale o Multipass

```bash
sudo snap install multipass --classic
```

## Instale o Vault para conexão do cliente

```bash
 curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
 sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 sudo apt update --fix-missing
 sudo apt -y install vault
```

# Instale o Vault

## Crie um cloud-init para a instância Vault com Multipass

```bash
echo '#cloud-config
write_files:
  - path: /etc/rc.local
    owner: root:root
    permissions: 0777
    content: |
      #!/bin/bash
      exec sudo vault server -config /opt/vault/config/config.hcl &
      exit 0
    append: true
  - path: /opt/vault/config/config.hcl
    owner: root:root
    permissions: 0600
    content: |
      storage "raft" {
        path    = "/opt/vault/data"
        node_id = "node1"
      }

      listener "tcp" {
        address     = "IPADDR:8200"
        tls_disable = "true"
      }

      api_addr = "http://IPADDR:8200"
      cluster_addr = "https://IPADDR:8201"
      ui = true
    append: true
runcmd:
 - curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
 - sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 - sudo apt update --fix-missing
 - sudo apt -y install vault
 - IPADDR=`hostname -I | tr -d [:blank:]`
 - sudo sed -i "s/"IPADDR"/"$IPADDR"/g" /opt/vault/config/config.hcl
 - sudo vault server -config /opt/vault/config/config.hcl &' > cloud-config-vault.yaml
```

## Crie uma instância Vault com Multipass

```bash
multipass launch focal -n vault -c 1 -m 1G -d 5G --cloud-init cloud-config-vault.yaml
```

## Adicione um alias de IP da instância de teste para teste.info

```bash
multipass info vault | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     vault.info/' | sudo tee -a /etc/hosts
```

## Crie uma variável com o IP da instância Vault

```bash
unset VAULT_IPADDR
export VAULT_IPADDR=`multipass info vault | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:]`
echo $VAULT_IPADDR
```

## Exporte a variável para conexão com o Vault

```bash
unset VAULT_ADDR
unset VAULT_TOKEN
export VAULT_ADDR="http://$VAULT_IPADDR:8200"
export VAULT_TOKEN=""
echo $VAULT_ADDR
echo $VAULT_TOKEN
```

## Verifique o status do servidor Vault

```bash
vault status
```

```text
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            1.8.1
Storage Type       raft
HA Enabled         true
```

## Inicialize o Vault

```bash
vault operator init
```

```text
Unseal Key 1: fH0L3kHWZJDsLbop2D/2vyKWC6mvRpoyk4xxBl3lyZPQ
Unseal Key 2: fDhV5nzviO4hyGMNVFULR59UdWQ1HziFV6f7o5NHsdoz
Unseal Key 3: jq8gxNblEcf7uInF9RRpHDaOk5H+AU0P14veBhVZRNWZ
Unseal Key 4: ErwurqiLYn1y/NurciJuKCHN0j6HPVaER+CwJRJNQN14
Unseal Key 5: 8EMJkT2WxtJnYMlfOQswaVG50AnbAuHwnHx7a7vm7qog

Initial Root Token: s.RxcP2G26ulCiCH5232SXuYut

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 keys to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

```bash
unset VAULT_ADDR
unset VAULT_TOKEN
export VAULT_ADDR="http://$VAULT_IPADDR:8200"
export VAULT_TOKEN="s.RxcP2G26ulCiCH5232SXuYut"
echo $VAULT_ADDR
echo $VAULT_TOKEN
```

## Dessele o Vault

```bash
vault status
```

```text
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    0/3
Unseal Nonce       n/a
Version            1.8.1
Storage Type       raft
HA Enabled         true
```

```bash
vault operator unseal
```

```text
Unseal Key (will be hidden):
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       af44ac63-6b9c-de44-7966-54eb2f9ec3a2
Version            1.8.1
Storage Type       raft
HA Enabled         true
```

```text
Unseal Key (will be hidden):
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       af44ac63-6b9c-de44-7966-54eb2f9ec3a2
Version            1.8.1
Storage Type       raft
HA Enabled         true

```

```text
Unseal Key (will be hidden):
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.8.1
Storage Type            raft
Cluster Name            vault-cluster-bf096a60
Cluster ID              834d6e2a-82a7-19a2-85a4-7903715a7fcc
HA Enabled              true
HA Cluster              n/a
HA Mode                 standby
Active Node Address     <none>
Raft Committed Index    24
Raft Applied Index      24
```

## Autentique-se como o token raiz inicial

```bash
vault login $VAULT_TOKEN
```

```text
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.RxcP2G26ulCiCH5232SXuYut
token_accessor       Qjl5Eft34vxbwiqnuxL11Se8
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

## Habilite um Mecanismo de Segredos

```bash
vault secrets enable -path=kv kv
```

```text
Success! Enabled the kv secrets engine at: kv/
```

OU

```bash
vault secrets enable kv
```

```bash
vault secrets list
```

```text
Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_4598cb70    per-token private secret storage
identity/     identity     identity_ddc00d32     identity store
kv/           kv           kv_52b568dd           n/a
sys/          system       system_7634e449       system endpoints used for control, policy and debugging
```

### Crie um segredo

```bash
vault kv put kv/myuser username=myuser password=mypassword
```

```text
Success! Data written to: kv/myuser
```

### Leia os segredos armazenados em kv/myuser

```bash
vault kv get kv/myuser
```

```text
====== Data ======
Key         Value
---         -----
password    mypassword
username    myuser
```

### Liste as chaves existentes no caminho kv

```bash
vault kv list kv/
```

```text
Keys
----
myuser
```

### Exclua os segredos em kv/myuser

```bash
vault kv delete kv/myuser
```

```text
Success! Data deleted (if it existed) at: kv/myuser
```

## Habilite o método de autenticação "userpass" habilitado em "userpass/"

```bash
vault auth enable userpass
```

```text
Success! Enabled userpass auth method at: userpass/
```

### Crie um usuário

```bash
vault write auth/userpass/users/myuser password=mypassword
```

```text
Success! Data written to: auth/userpass/users/myuser
```

### Listar usuário

```bash
vault list auth/userpass/users/
```

```text
Keys
----
myuser
```

### Excluir usuário

```bash
vault delete auth/userpass/users/myuser
```

```text
Success! Data deleted (if it existed) at: auth/userpass/users/myuser
```

### Listar todos os métodos de autenticação habilitados

```bash
vault auth list
```

```text
Path         Type        Accessor                  Description
----         ----        --------                  -----------
token/       token       auth_token_1e18c48a       token based credentials
userpass/    userpass    auth_userpass_06b8862c    n/a
```

### Listar informações detalhadas do método de autenticação

```bash
vault auth list -detailed
```

```text
Path         Plugin      Accessor                  Default TTL    Max TTL    Token Type         Replication    Seal Wrap    External Entropy Access    Options    Description                UUID
----         ------      --------                  -----------    -------    ----------         -----------    ---------    -----------------------    -------    -----------                ----
token/       token       auth_token_1e18c48a       system         system     default-service    replicated     false        false                      map[]      token based credentials    58cfdc65-7ede-4594-796d-76d70dca389f
userpass/    userpass    auth_userpass_06b8862c    system         system     default-service    replicated     false        false                      map[]      n/a                        c0b32e87-6016-97a6-20a4-018c8e2dd98a
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
 - microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

## Crie uma instância MicroK8s

```bash
multipass launch focal -n microk8s -c 2 -m 2G -d 10G --cloud-init cloud-config-microk8s.yaml
```

## Exporte a configuração atual do MicroK8s para uso com o Kubectl

### Crie a pasta para armazenar a configuração do cluster Kubernetes na instância de teste

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Exporte a configuração do MicroK8s na instância de teste para a pasta criada

```bash
multipass exec microk8s sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

### Use em sua sessão a configuração exportada como padrão para uso com o Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

### Instale o Kubectl

```bash
sudo snap install kubectl --classic
```

```bash
kubectl get no
```

```txt
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   1m    v1.21.3-3+90fd5f3d2aea0a
```

### Adicione um alias de IP da instância de teste para microk8s.info

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.info/' | sudo tee -a /etc/hosts
```

### Exporte a variável para conexão com o Vault

```bash
unset VAULT_IPADDR
unset VAULT_ADDR
unset VAULT_TOKEN
export VAULT_IPADDR=`multipass info vault | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:]`
export VAULT_ADDR="http://$VAULT_IPADDR:8200"
export VAULT_TOKEN="s.RxcP2G26ulCiCH5232SXuYut"
echo $VAULT_IPADDR
echo $VAULT_ADDR
echo $VAULT_TOKEN
```

### Dessele o Vault

```bash
vault status
```

```bash
vault operator unseal
```

### Habilite um Mecanismo de Segredos

```bash
vault secrets enable kv
```

```text
Success! Enabled the kv secrets engine at: kv/
```

### Crie um segredo

```bash
vault kv put kv/devwebapp/config username='giraffe' password='salsa'
```

```text
Success! Data written to: kv/devwebapp/config
```

### Verifique se o segredo está armazenado no caminho kv/devwebapp/config

```bash
vault kv get -format=json kv/devwebapp/config | jq ".data"
```

```text
{
  "password": "salsa",
  "username": "giraffe"
}
```

### Crie uma conta de serviço Kubernetes chamada internal-app

```bash
kubectl create sa internal-app
```

### Defina um pod chamado devwebapp com a aplicação web que define VAULT_ADDR para EXTERNAL_VAULT_ADDR

```bash
cat > devwebapp.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: devwebapp
  labels:
    app: devwebapp
spec:
  serviceAccountName: internal-app
  containers:
    - name: app
      image: burtlo/devwebapp-ruby:k8s
      env:
      - name: VAULT_ADDR
        value: "$VAULT_ADDR"
      - name: VAULT_TOKEN
        value: $VAULT_TOKEN
EOF
```

### Crie o pod devwebapp.

```bash
kubectl apply -f devwebapp.yaml
```

### Obtenha todos os pods no namespace padrão

```bash
kubectl get pods
```

```text
NAME        READY   STATUS    RESTARTS   AGE
devwebapp   1/1     Running   0          60s
```

### Crie um yaml para o endpoint apontando para a instância vault.info

```bash
echo 'apiVersion: v1
items:
- apiVersion: v1
  kind: Service
  metadata:
    name: external-vault-service
    namespace: default
  spec:
    clusterIP: None
    ports:
    - name: external-vault-service
      port: 8200
      targetPort: 8200
- apiVersion: v1
  kind: Endpoints
  metadata:
    name: external-vault-endpoint
    namespace: default
  subsets:
  - addresses:
    - ip: VaultIP
    ports:
    - name: external-vault-service
      port: 8200
      protocol: TCP
kind: List
metadata: {}' > external_vault_endpoint.yaml
```

### Adicione o IP da instância Vault ao yaml do endpoint

```bash
for i in `multipass info vault | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:]` ; do sed -i s/VaultIP/$i/ external_vault_endpoint.yaml ; done
```

### Crie o endpoint apontando para a instância Vault

```bash
kubectl apply -f external_vault_endpoint.yaml
```

Fontes:

https://learn.hashicorp.com/tutorials/vault/getting-started-deploy

https://learn.hashicorp.com/tutorials/vault/getting-started-deploy?in=vault/getting-started

https://learn.hashicorp.com/tutorials/vault/getting-started-first-secret

https://learn.hashicorp.com/tutorials/vault/getting-started-secrets-engines?in=vault/getting-started

https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes

https://www.vaultproject.io/docs/secrets/kv/kv-v2

https://www.vaultproject.io/docs/commands/auth/enable
