_Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)_

# Implantação Leve em Kubernetes com Kustomize + Kapp

---

## 1. Visão Geral e Filosofia

O **kapp** é uma ferramenta de linha de comando (CLI) focada no gerenciamento do ciclo de vida de aplicações no Kubernetes. Em vez de operar como um motor de _templates_ ou como um operador interno contínuo, o `kapp` trata conjuntos de recursos declarativos como uma aplicação unificada.

A abordagem **Kustomize + kapp** estabelece uma divisão clara de responsabilidades:

```text
┌────────────────────────────────┐     ┌────────────────────────────────┐     ┌────────────────────────────────┐
│           Kustomize            │     │              kapp              │     │         Kubernetes API         │
│  Renderização de Manifestos    │ ──> │  Orquestração da Implantação   │ ──> │  Execução do Estado Desejado   │
│  (Transformações em YAML puro) │     │  (Diff, Pruning, Dependências) │     │  (GKE / EKS / AKS / On-Prem)   │
└────────────────────────────────┘     └────────────────────────────────┘     └────────────────────────────────┘
```

- **Kustomize:** Concatena, altera e gera os manifestos YAML estáticos sem introduzir sintaxes de _template_ complexas.
- **kapp:** Compara os manifestos com o estado atual do cluster, exibe um _diff_ preciso, aplica as mudanças na ordem correta, aguarda a prontidão dos serviços e remove objetos obsoletos.
- **Cluster Kubernetes:** Executa exclusivamente as cargas de trabalho. Não necessita de controladores adicionais rodando em segundo plano para processar implantações.

---

## 2. Problemas e Dores Resolvidas

### A. Limitações do `kubectl apply`

- **Falta de Pruning Seguro:** O `kubectl apply --prune` é propenso a apagar recursos indevidos por depender unicamente de _labels_, sendo considerado inseguro para uso em produção.
- **Execução Assíncrona:** O `kubectl` envia os manifestos para a API e encerra a execução. Ele não aguarda a inicialização dos Pods, _Health Checks_ ou _Volume Attachments_, dificultando o controle em pipelines de CI/CD.
- **Inexistência de Ordenação de Dependências:** Não há uma garantia nativa de que um `CustomResourceDefinition` (CRD) ou `ConfigMap` seja criado e esteja pronto antes de um `Deployment` ser iniciado.

### B. Complexidade do GitOps Tradicional (Argo CD / Flux)

- **Sobrecarga de Infraestrutura (_Overhead_):** Exige a execução de múltiplos controladores, Pods e CRDs dentro do cluster, consumindo memória e CPU unicamente para manter o _loop_ de reconciliação.
- **Dificuldade na Inspeção Prévia do Diff:** No modelo GitOps por sincronização automática, a aplicação ocorre após o _commit_. Validar o _diff_ exato de uma alteração de forma interativa antes da aplicação no cluster torna-se um processo mais complexo.

### C. Fragilidades do Helm

- **Injeção de Sintaxe via Go Templates:** A interpolação de strings em arquivos YAML pode originar falhas de indentação e erros difíceis de depurar em pipelines automatizados.
- **Estado Mascarado:** O histórico de _releases_ do Helm fica oculto em Secrets codificados em Base64, dificultando a auditoria direta via ferramentas nativas do Kubernetes.

---

## 3. Comparativo Técnico de Soluções

| Critério                            | `kubectl apply`              | Helm                          | Argo CD / Flux            | Kustomize + kapp                                |
| ----------------------------------- | ---------------------------- | ----------------------------- | ------------------------- | ----------------------------------------------- |
| **Controladores no Cluster**        | Nenhum                       | Nenhum                        | Múltiplos operadores/CRDs | **Nenhum (0 in-cluster controllers)**           |
| **Geração de Manifestos**           | YAML Puro                    | Go Templates                  | Helm / Kustomize nativo   | **Kustomize (YAML Declarativo)**                |
| **Cálculo de Diff**                 | Superficial (`kubectl diff`) | Requer plugin (`helm diff`)   | Interface Web / PRs       | **Nativo, detalhado e interativo**              |
| **Garantia de Prontidão**           | Não aguarda                  | Parcial (`--wait`)            | Gerenciado pelo Operador  | **Aguarda a convergência de estado por padrão** |
| **Limpeza de Recursos (_Pruning_)** | Manual / Perigoso            | Limitado ao escopo do Release | Automático via GitOps     | **Automático, explícito no diff e rastreado**   |
| **Execução Principal**              | Local / CI/CD                | Local / CI/CD                 | Dentro do Cluster         | **Local / CI/CD**                               |

---

## 4. Arquitetura e Fluxo de Funcionamento

O `kapp` não depende de um banco de dados externo. O cálculo do impacto de uma alteração é feito através de uma **leitura tripla**:

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                        Processo de Avaliação (Diff)                      │
├──────────────────────────┬──────────────────────────┬───────────────────┤
│    1. Estado Desejado    │    2. Estado Gravado     │  3. Estado Atual  │
│  (Saída do Kustomize)    │   (ConfigMap do kapp)    │   (Kubernetes API)│
└────────────┬─────────────┴────────────┬─────────────┴─────────┬─────────┘
             │                          │                       │
             └──────────────────────────┼───────────────────────┘
                                        ▼
                           ┌────────────────────────┐
                           │ Cálculo das Operações  │
                           │  (create, update,      │
                           │   delete, noop)        │
                           └────────────────────────┘
```

1. **Estado Desejado:** Os manifestos renderizados pelo `kustomize build`.
2. **Estado Gravado:** Um `ConfigMap` gerenciado pelo `kapp` que armazena a lista e os metadados de todos os recursos pertencentes àquela aplicação específica.
3. **Estado Atual (_Live State_):** A consulta em tempo real à API do Kubernetes para identificar alterações externas (_drift_).

### Ordenação Automática (_Apply Ordering_)

O `kapp` calcula implicitamente a ordem correta de aplicação dos recursos (exemplo: `Namespaces` -> `CRDs` -> `ConfigMaps/Secrets` -> `Deployments/StatefulSets` -> `Services`). Também permite a definição de regras customizadas via _annotations_ (`kapp.k14s.io/change-group` e `kapp.k14s.io/change-rule`).

---

## 5. Laboratório Prático (PoC): Setup do Ambiente com Multipass + MicroK8s

Para simular o fluxo real, a VM do Multipass executará unicamente o cluster Kubernetes (MicroK8s), enquanto as ferramentas de gerenciamento (`kustomize` e `kapp`) rodarão diretamente na sua máquina local (Host).

### Criar a Definição de Cloud-Init

```bash
echo '#cloud-config
runcmd:
- apt update --fix-missing
- snap refresh
- snap install microk8s --classic
- microk8s status --wait-ready
- microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

### Criar a Máquina Virtual

```bash
multipass launch focal -n microk8s -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
```

### Criar Diretório para as Configurações do Kubeconfig no Host

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Exportar a Configuração do Cluster para o Host

```bash
multipass exec microk8s sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

### Redirecionar o Endpoint da API para o IP Real da VM

```bash
VM_IP=$(multipass info microk8s | grep IPv4 | awk '{print $2}')
sed -i "s/127.0.0.1/${VM_IP}/g" $HOME/.kube/configs/config-microk8s
```

### Configurar a Variável de Ambiente KUBECONFIG

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

### Definir Permissões Restritas no Arquivo

```bash
chmod 0600 $KUBECONFIG
```

### Validar o Contexto no Host

```bash
kubectl config get-contexts
```

```text
CURRENT   NAME       CLUSTER            AUTHINFO   NAMESPACE
*         microk8s   microk8s-cluster   admin
```

### Validar a Conexão com o Cluster

```bash
kubectl get nodes
```

```text
NAME       STATUS   ROLES    AGE     VERSION
microk8s   Ready    <none>   2m15s   v1.31.1
```

---

## 6. Instalação das CLIs no Host (Kustomize + kapp)

As operações de renderização e controle de versão declarativo ocorrem exclusivamente na sua máquina de desenvolvimento.

### Instalar Kustomize (Binário Oficial)

```bash
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/
```

### Instalar kapp (Carvel Suite)

```bash
curl -L https://carvel.dev/install.sh | sudo bash
```

---

## 7. Estrutura da Aplicação e Implantação (Kustomize Declarativo)

Organização dos manifestos em base e sobreposições (_overlays_) para os testes locais.

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

### Criar os Diretórios

```bash
mkdir -p poc-kapp/deploy/base poc-kapp/deploy/overlays/local
cd poc-kapp
```

### Criar o Manifesto do Deployment Base (`deploy/base/deployment.yaml`)

```bash
cat <<EOF > deploy/base/deployment.yaml
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

### Criar o Manifesto do Service Base (`deploy/base/service.yaml`)

```bash
cat <<EOF > deploy/base/service.yaml
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

### Criar o Kustomization Base (`deploy/base/kustomization.yaml`)

```bash
cat <<EOF > deploy/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
EOF
```

### Criar o Overlay Local (`deploy/overlays/local/kustomization.yaml`)

```bash
cat <<EOF > deploy/overlays/local/kustomization.yaml
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

## 8. Execução da PoC com kapp (Host -> VM)

### Realizar o Deploy Inicial

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local)
```

```text
Target cluster: https://192.168.64.5:16443 (microk8s-cluster)

Namespace   Name        Kind        Op      Op st.  Wait to
(cluster)   valkey-poc  Namespace   create  -       reconcile
valkey-poc  valkey      Service     create  -       reconcile
valkey-poc  valkey      Deployment  create  -       reconcile

Op:      3 create, 0 delete, 0 update, 0 noop
Wait to: 3 reconcile

Continue? [yN]: y
```

### Comandos de Inspeção e Operação

```bash
# Listar aplicações gerenciadas no cluster
kapp list
```

```bash
# Visualizar a árvore de recursos
kapp inspect -a valkey-app --tree
```

```bash
# Acompanhar os logs agregados de todos os Pods da aplicação
kapp logs -a valkey-app -f
```

### Testar Cálculo de Diff (Scaling + Imagem)

```bash
cat <<EOF > deploy/overlays/local/kustomization.yaml
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

### Testar Pruning Automático (Remoção do Service)

```bash
sed -i '/- service.yaml/d' deploy/base/kustomization.yaml
```

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local)
```

```text
Target cluster: https://192.168.64.5:16443 (microk8s-cluster)

Namespace   Name    Kind     Op      Op st.  Wait to
valkey-poc  valkey  Service  delete  -       reconcile

Op:      0 create, 1 delete, 0 update, 0 noop
Wait to: 1 reconcile

Continue? [yN]: y
```

---

## 9. Integração em Esteiras de CI/CD

Por ser uma ferramenta de linha de comando _stateless_, o **kapp** é ideal para esteiras de integração e entrega contínuas (CI/CD). Ele substitui o `kubectl apply` com vantagens decisivas para a automação:

```text
  [ Push / Merge Request ]
             │
             ▼
┌──────────────────────────┐     1. Checkout do Repositório Git
│                          │ ──> 2. Renderização: kustomize build
│   Runner de CI/CD        │ ──> 3. Validação: kapp deploy --diff-run
│   (GitHub/GitLab/Jenkins)│ ──> 4. Aplicação: kapp deploy --yes
└──────────────────────────┘
             │ (HTTPS / Kubeconfig)
             ▼
┌──────────────────────────┐
│   Kubernetes Cluster     │
└──────────────────────────┘
```

### Vantagens na Automação

1. **Feedback Síncrono:** O `kapp` aguarda a convergência de estado (_health check_). Se um Pod falhar ao inicializar em um deploy, o job do CI/CD **falha imediatamente**.
2. **Validação Prévia em Pull Requests:** Uso da flag `--diff-run` para prever exatamente quais objetos serão alterados sem aplicar modificações no cluster.
3. **Pruning Seguro:** Recursos removidos do repositório Git são deletados do cluster de forma controlada na execução do pipeline.

---

### Exemplo 1: Pipeline no GitHub Actions (`.github/workflows/deploy.yaml`)

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
      - name: Checkout do Código
        uses: actions/checkout@v4

      - name: Instalar Kustomize e kapp
        run: |
          curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
          sudo mv kustomize /usr/local/bin/
          curl -L https://carvel.dev/install.sh | sudo bash

      - name: Configurar Kubeconfig
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG_DATA }}

      - name: Renderizar e Implantar via kapp
        run: |
          kustomize build deploy/overlays/production | kapp deploy \
            --app valkey-app \
            --namespace production \
            --file - \
            --yes
```

---

### Exemplo 2: Pipeline no GitLab CI (`.gitlab-ci.yml`)

```yaml
stages:
  - validate
  - deploy

.kapp-setup: &kapp-setup
  before_script:
    - curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && mv kustomize /usr/local/bin/
    - curl -L https://carvel.dev/install.sh | bash
    - mkdir -p ~/.kube && echo "$KUBE_CONFIG_DATA" > ~/.kube/config

# Validação do Diff em Merge Requests
preview-diff:
  stage: validate
  <<: *kapp-setup
  script:
    - kustomize build deploy/overlays/production | kapp deploy -a valkey-app -n production -f - --diff-run
  only:
    - merge_requests

# Implantação em Produção
deploy-production:
  stage: deploy
  <<: *kapp-setup
  script:
    - kustomize build deploy/overlays/production | kapp deploy -a valkey-app -n production -f - --yes
  only:
    - main
```

---

### Boas Práticas em CI/CD

- **Flag `--yes` (`-y`):** Sempre inclua a flag `--yes` nos jobs de implantação para desabilitar a confirmação interativa no terminal.
- **Containers Utilitários:** Utilize imagens Docker customizadas pré-instalando `kustomize` e `kapp` para reduzir o tempo de execução do pipeline.
- **Autenticação Curta (OIDC):** Dê preferência à autenticação OIDC (OpenID Connect) com o provedor de nuvem em vez de salvar arquivos de `kubeconfig` estáticos nos segredos do repositório.

---

## 10. Gestão de Estado, Backup e Recuperação de Desastres

### Armazenamento de Estado

O estado de cada aplicação é mantido em um `ConfigMap` no Kubernetes, utilizando a convenção de nome `<nome-da-app>.apps.k14s.io` dentro do namespace alvo.

### A. Estratégia de Backup do Estado

Para exportar o estado atual gerenciado pelo `kapp`:

```bash
#!/usr/bin/env bash
BACKUP_DIR="./backups/kapp"
mkdir -p "${BACKUP_DIR}"

kubectl get configmap -n valkey-poc -l kapp.k14s.io/app \
  -o yaml > "${BACKUP_DIR}/kapp-state-valkey-$(date +%Y%m%d).yaml"
```

### B. Procedimentos de Recuperação de Desastres (DR)

#### Cenário 1: Deleção Acidental do ConfigMap de Estado

Se o `ConfigMap` de controle do `kapp` for removido, os Pods e serviços da aplicação **não serão afetados**. Para restabelecer o acompanhamento:

1. Execute o comando de deploy apontando para o manifesto do Git:

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local) --yes
```

2. O `kapp` identificará os recursos existentes na API do Kubernetes e **readotará** todos os objetos sem causar interrupções nos Pods em execução.

#### Cenário 2: Reconstrução Total do Cluster

Em caso de perda total do cluster:

1. A restauração não depende do backup do `ConfigMap` antigo, pois a fonte primária da verdade é o repositório **Git**.
2. Após recriar o cluster, execute a esteira de implantação:

```bash
kapp deploy -a valkey-app -f <(kustomize build deploy/overlays/local) --yes
```

3. O `kapp` recriará os Namespaces, ConfigMaps, Secrets, Workloads e Services respeitando a árvore de dependências.

---

## 11. Cleanup (Teardown)

### Remover a Aplicação do Cluster

```bash
kapp delete -a valkey-app
```

### Destruir a VM no Multipass

```bash
multipass delete microk8s
multipass purge
```

---

## 12. Fontes Oficiais, Licenciamento e Estado de Maturidade

### **kapp (Carvel Suite)**

- **Documentação Oficial:** [carvel.dev/kapp](https://carvel.dev/kapp/)
- **Repositório do Código-Fonte:** [github.com/carvel-dev/kapp](https://github.com/carvel-dev/kapp)
- **Licença de Software:** Apache License 2.0 (Open Source)
- **Estado de Maturidade:** **CNCF Sandbox Project** (integrante da suíte de ferramentas Carvel aceita pela Cloud Native Computing Foundation).

### **Kustomize**

- **Documentação Oficial:** [kustomize.io](https://kustomize.io/) | [kubectl-docs.kubernetes.io](https://www.google.com/search?q=https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- **Repositório do Código-Fonte:** [github.com/kubernetes-sigs/kustomize](https://github.com/kubernetes-sigs/kustomize)
- **Licença de Software:** Apache License 2.0 (Open Source)
- **Estado de Maturidade:** **Kubernetes SIG Project / Subprojeto Oficial** (subprojeto mantido pelo Kubernetes Special Interest Group e integrado nativamente ao subcomando `kubectl kustomize` desde a versão 1.14 do Kubernetes).

### **Ferramentas Mencionadas**

- **Helm:** [helm.sh](https://helm.sh/) | Licença Apache 2.0 | Estado: **CNCF Graduated Project**
- **Argo CD:** [argoproj.github.io/cd](https://argoproj.github.io/cd/) | Licença Apache 2.0 | Estado: **CNCF Graduated Project**
- **Flux:** [fluxcd.io](https://fluxcd.io/) | Licença Apache 2.0 | Estado: **CNCF Graduated Project**
