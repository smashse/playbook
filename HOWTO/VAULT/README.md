# Requirements for this POC

In this POC we will use Multipass to create instances to install the Vault and Microk8s, then establishing the Vault server as a credential manager for the Kubernetes cluster provisioned with Microk8s.

## Intall Multipass

```bash
sudo snap install mulipass --classic
```

## Install Vault for client connection

```bash
 curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
 sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 sudo apt update --fix-missing
 sudo apt -y install vault
```

# Install Vault

## Create a cloud-init for the Vault instance with Multipass

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

## Create Vault instance with Multipass

```bash
multipass launch focal -n vault -c 1 -m 1G -d 5G --cloud-init cloud-config-vault.yaml
```

## Add an IP alias of the test instance to teste.info

```bash
multipass info vault | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     vault.info/' | sudo tee -a /etc/hosts
```

## Create a variable with the IP of the Vault instance

```bash
unset VAULT_IPADDR
export VAULT_IPADDR=`multipass info vault | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:]`
echo $VAULT_IPADDR
```

## Export variable for connection to Vault

```bash
unset VAULT_ADDR
unset VAULT_TOKEN
export VAULT_ADDR="http://$VAULT_IPADDR:8200"
export VAULT_TOKEN=""
echo $VAULT_ADDR
echo $VAULT_TOKEN
```

## Check status of the Vault server

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

## initialize Vault

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

## Unseal Vault

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

## Authenticate as the initial root token

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

## Enable a Secrets Engine

```bash
vault secrets enable -path=kv kv
```

```text
Success! Enabled the kv secrets engine at: kv/
```

OR

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

### Create a secret

```bash
vault kv put kv/myuser username=myuser password=mypassword
```

```text
Success! Data written to: kv/myuser
```

### Read the secrets stored in kv/myuser

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

### List existing keys at the kv path

```bash
vault kv list kv/
```

```text
Keys
----
myuser
```

### Delete the secrets at kv/myuser

```bash
vault kv delete kv/myuser
```

```text
Success! Data deleted (if it existed) at: kv/myuser
```

## Enable the auth method "userpass" enabled at "userpass/"

```bash
vault auth enable userpass
```

```text
Success! Enabled userpass auth method at: userpass/
```

### Create a user

```bash
vault write auth/userpass/users/myuser password=mypassword
```

```text
Success! Data written to: auth/userpass/users/myuser
```

### List user

```bash
vault list auth/userpass/users/
```

```text
Keys
----
myuser
```

### Delete user

```bash
vault delete auth/userpass/users/myuser
```

```text
Success! Data deleted (if it existed) at: auth/userpass/users/myuser
```

### List all enabled auth methods

```bash
vault auth list
```

```text
Path         Type        Accessor                  Description
----         ----        --------                  -----------
token/       token       auth_token_1e18c48a       token based credentials
userpass/    userpass    auth_userpass_06b8862c    n/a
```

### List detailed auth method information

```bash
vault auth list -detailed
```

```text
Path         Plugin      Accessor                  Default TTL    Max TTL    Token Type         Replication    Seal Wrap    External Entropy Access    Options    Description                UUID
----         ------      --------                  -----------    -------    ----------         -----------    ---------    -----------------------    -------    -----------                ----
token/       token       auth_token_1e18c48a       system         system     default-service    replicated     false        false                      map[]      token based credentials    58cfdc65-7ede-4594-796d-76d70dca389f
userpass/    userpass    auth_userpass_06b8862c    system         system     default-service    replicated     false        false                      map[]      n/a                        c0b32e87-6016-97a6-20a4-018c8e2dd98a
```

Sources:

https://learn.hashicorp.com/tutorials/vault/getting-started-deploy
https://learn.hashicorp.com/tutorials/vault/getting-started-deploy?in=vault/getting-started
https://learn.hashicorp.com/tutorials/vault/getting-started-first-secret
https://learn.hashicorp.com/tutorials/vault/getting-started-secrets-engines?in=vault/getting-started
https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes
https://www.vaultproject.io/docs/secrets/kv/kv-v2
https://www.vaultproject.io/docs/commands/auth/enable
