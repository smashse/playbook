*Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)*

# Requisitos da Prova de Conceito (POC)

Nesta POC, usaremos o **Multipass** para criar instâncias para instalar o **DataDog** e o **MicroK8s**. O objetivo é estabelecer o DataDog como uma ferramenta de observabilidade para o cluster Kubernetes provisionado com o MicroK8s.

## 1. Instale o Multipass

Para instalar o Multipass, execute o seguinte comando:

```bash
sudo snap install multipass --classic
```

## 2. Configuração do MicroK8s

MicroK8s é a menor, mais rápida e totalmente compatível distribuição Kubernetes que acompanha as versões upstream e simplifica o clustering. É ideal para desenvolvimento offline, prototipagem e testes.

### 2.1 Crie um Template MicroK8s

Crie um arquivo `cloud-config-microk8s.yaml` para configurar a instância do MicroK8s:

```bash
echo '#cloud-config
runcmd:
  - apt update --fix-missing
  - snap refresh
  - snap install microk8s --classic
  - microk8s status --wait-ready
  - microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

### 2.2 Crie uma Instância MicroK8s

Inicie uma instância do MicroK8s usando o Multipass:

```bash
multipass launch noble -n microk8s -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s.yaml
```

### 2.3 Exporte a Configuração do MicroK8s para o Kubectl

#### 2.3.1 Crie um Diretório para Configurações do Kubernetes

```bash
mkdir -p $HOME/.kube/configs
```

#### 2.3.2 Exporte a Configuração do MicroK8s

Exporte a configuração do MicroK8s para o diretório criado:

```bash
multipass exec microk8s -- sudo microk8s config | tee $HOME/.kube/configs/config-microk8s
```

#### 2.3.3 Defina a Configuração Exportada como Padrão para o Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
chmod 0600 $KUBECONFIG
```

#### 2.3.4 Instale o Kubectl

Instale o Kubectl usando o Snap:

```bash
sudo snap install kubectl --classic
```

Verifique a instalação:

```bash
kubectl get no
```

#### 2.3.5 Instale o Helm

```bash
sudo snap install helm --classic
```

**Saída:**

```txt
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   10m   v1.32.1
```

### 2.4 Adicione um Alias de IP para o MicroK8s

Adicione um alias de IP para a instância do MicroK8s para `microk8s.local`:

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.local/' | sudo tee -a /etc/hosts
```

### 2.5 Acesse o MicroK8s via URL

Você pode acessar o MicroK8s através da seguinte URL:
<http://microk8s.local>

## 3. Configuração do DataDog

<details>
<summary><b>Diferenças entre US1, US3 e US5 no Datadog</b></summary>

No Datadog, **US1**, **US3** e **US5** referem-se a diferentes **regiões (endpoints)** onde os dados são processados e armazenados. Essas regiões são projetadas para atender clientes em localizações geográficas específicas ou para atender a requisitos de conformidade. Abaixo estão as principais diferenças:

---

### **US1 (Região US - Padrão)**

- **Endpoint**: `https://datadoghq.com`
- **Descrição**: A região primária e padrão do Datadog para clientes nos Estados Unidos.
- **Residência de Dados**: Os dados são armazenados e processados nos Estados Unidos.
- **Caso de Uso**: Ideal para clientes que não possuem requisitos específicos de residência de dados fora dos EUA.
- **Desempenho**: Melhor desempenho para usuários e aplicações localizadas nos EUA.

---

### **US3 (Região US3)**

- **Endpoint**: `https://us3.datadoghq.com`
- **Descrição**: Uma região separada do Datadog, também localizada nos Estados Unidos, mas isolada da US1.
- **Residência de Dados**: Os dados são armazenados e processados nos Estados Unidos, mas em uma infraestrutura diferente da US1.
- **Caso de Uso**: Projetado para clientes que precisam de isolamento da região primária US1, frequentemente por motivos de conformidade, regulatórios ou organizacionais.
- **Desempenho**: Semelhante à US1 para usuários e aplicações nos EUA.

---

### **US5 (Região US5)**

- **Endpoint**: `https://us5.datadoghq.com`
- **Descrição**: Outra região isolada do Datadog nos Estados Unidos, distinta da US1 e US3.
- **Residência de Dados**: Os dados são armazenados e processados nos Estados Unidos, mas em uma infraestrutura separada.
- **Caso de Uso**: Usado por clientes que requerem isolamento adicional ou possuem necessidades específicas de conformidade que não podem ser atendidas pela US1 ou US3.
- **Desempenho**: Comparável à US1 e US3 para usuários e aplicações nos EUA.

---

### Principais Diferenças:

| Característica  | US1                    | US3                        | US5                        |
| --------------- | ---------------------- | -------------------------- | -------------------------- |
| **Endpoint**    | `datadoghq.com`        | `us3.datadoghq.com`        | `us5.datadoghq.com`        |
| **Localização** | US (Primária)          | US (Isolada)               | US (Isolada)               |
| **Caso de Uso** | Região US padrão       | Necessidades de conformidade/isolamento | Necessidades adicionais de isolamento |
| **Desempenho**  | Otimizado para usuários dos EUA | Otimizado para usuários dos EUA | Otimizado para usuários dos EUA |

---

### Como Escolher a Região Certa:

- **US1**: Use esta região se você não tiver requisitos específicos de conformidade ou isolamento.
- **US3/US5**: Use estas regiões se precisar de infraestrutura isolada para atender a requisitos de conformidade, regulatórios ou organizacionais.

---

### Observação:

- Dados e configurações **não são compartilhados** entre essas regiões. Se você trocar de região, precisará configurar seu ambiente Datadog (dashboards, monitores, etc.) separadamente.
- Certifique-se de que a ingestão de dados e as chamadas de API sejam direcionadas para o endpoint correto da região escolhida.

[Introdução aos Sites Datadog](https://docs.datadoghq.com/getting_started/site/)

</details>

### 3.1 Começando com o Nível Gratuito do DataDog

1. Visite o [site do Datadog](https://www.datadoghq.com).
2. Crie uma conta gratuita.
3. Siga as instruções para instalar o Datadog Agent em seu ambiente (local ou na nuvem).

### 3.2 Instale o Datadog Agent

O Datadog Agent coleta métricas e eventos de seus sistemas e aplicativos. Instale pelo menos um Agent em qualquer lugar, até mesmo em sua estação de trabalho.

#### 3.2.1 Instalando no Kubernetes

<details>
<summary><b>Opção 1: Usando o Datadog Operator</b></summary>

O Datadog Operator é uma forma de implantar o Datadog Agent no Kubernetes e OpenShift. Ele simplifica a implantação e reduz o risco de configuração incorreta.

##### 3.2.1.1 Instale o Datadog Operator

Instale o Datadog Operator no namespace atual:

```bash
helm repo add datadog https://helm.datadoghq.com
helm install datadog-operator datadog/datadog-operator
kubectl create secret generic datadog-secret --from-literal api-key="SUA_API_KEY"
```

##### 3.2.1.2 Configure `datadog-agent.yaml`

Para configurar o Datadog Agent nas distribuições AKS, Openshift e TKG, consulte a [documentação das distribuições Kubernetes](https://docs.datadoghq.com/containers/kubernetes/distributions/?tab=operator).

Configure o Datadog Agent para sua distribuição Kubernetes:

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

##### 3.2.1.3 Implante o Datadog Agent

Aplique a configuração:

```bash
kubectl apply -f datadog-agent.yaml
```

##### 3.2.1.4 Confirme a Instalação do Agent

Consulte os pods para confirmar a instalação:

```bash
kubectl get pods -l app.kubernetes.io/component=agent
kubectl get pods -l app.kubernetes.io/managed-by=datadog-operator
```

</details>

<details>
<summary><b>Opção 2: Usando o Helm Chart</b></summary>

Você pode usar o Helm chart do Datadog para instalar o Datadog Agent em todos os nós do seu cluster por meio de um DaemonSet.

##### 3.2.2.1 Adicione o Repositório Helm do Datadog

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
kubectl create secret generic datadog-secret --from-literal api-key="SUA_API_KEY"
```

##### 3.2.2.2 Configure `datadog-values.yaml`

Para configurar o Datadog Agent nas distribuições AKS, Openshift e TKG, consulte a [documentação das distribuições Kubernetes](https://docs.datadoghq.com/containers/kubernetes/distributions/?tab=helm).

Configure o Datadog Agent para sua distribuição Kubernetes:

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

##### 3.2.2.3 Implante o Datadog Agent

Instale o Datadog Agent usando o Helm:

```bash
helm install datadog-agent -f datadog-values.yaml datadog/datadog
```

##### 3.2.2.4 Confirme a Instalação do Agent

Consulte os pods para confirmar a instalação:

```bash
kubectl get pods -l app.kubernetes.io/component=agent
kubectl get pods -l app.kubernetes.io/managed-by=Helm
```

</details>
