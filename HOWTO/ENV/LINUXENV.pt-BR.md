*Read this in other languages: [en-US](LINUXENV.md), [pt-BR](LINUXENV.pt-BR.md)*

# Instalando o snapd

Snaps podem ser usados em todas as principais distribuições Linux, incluindo Ubuntu, Linux Mint, Debian e Fedora.

O Snap vem pré-instalado na maioria dos sistemas baseados em Ubuntu. Instruções de instalação podem ser encontradas no link abaixo para distribuições sem o snap pré-instalado.

<https://snapcraft.io/docs/installing-snapd>

Instalação de programas para configurar o ambiente.

```bash
sudo apt -y install curl jq unzip
```

## Instale o Firefox ESR

Firefox para sua empresa.

<https://www.mozilla.org/pt-BR/firefox/enterprise/>

<https://snapcraft.io/firefox>

```bash
sudo snap install firefox --channel=esr/stable
```

## Instale o Google Chrome

O navegador construído pelo Google.

<https://www.google.com/intl/pt-BR/chrome/>

<https://chromeenterprise.google/browser/>

<https://www.google.com/linuxrepositories/>

```bash
curl -fsSL 'https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb stable main" | sudo tee -a /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update --fix-missing
sudo apt -y install google-chrome-stable
```

## Instale o VSCodium

VSCodium é uma distribuição binária do editor VS Code da Microsoft, orientada pela comunidade e com licença livre.

<https://vscodium.com/#intro>

<https://snapcraft.io/codium>

```bash
sudo snap install codium --classic
```

## Instale o Visual Studio Code

Visual Studio Code é um editor de código fonte leve, mas poderoso, que roda no seu desktop.

<https://code.visualstudio.com/>

<https://snapcraft.io/code>

```bash
sudo snap install code --classic
```

## Instale o Kubectl

A ferramenta de linha de comando do Kubernetes, kubectl, permite que você execute comandos em clusters Kubernetes.

<https://kubernetes.io/docs/tasks/tools/>

<https://snapcraft.io/kubectl>

```bash
sudo snap install kubectl --classic
```

### Instale o Krew e o Neat

#### Krew

Krew é o gerenciador de plugins para a ferramenta de linha de comando kubectl.

<https://krew.sigs.k8s.io/>

<https://krew.sigs.k8s.io/docs/user-guide/setup/install/>

```bash
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
```

```bash
echo "
#KREW
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"" | tee -a ~/.bashrc
```

```bash
source ~/.bashrc
```

#### Neat

Limpe a saída yaml e json do Kubernetes para torná-la legível.

<https://github.com/itaysk/kubectl-neat>

<https://github.com/itaysk/kubectl-neat#installation>

```bash
kubectl krew install neat
```

## Instale o Helm

Helm é a melhor maneira de encontrar, compartilhar e usar software construído para Kubernetes.

<https://helm.sh/>

<https://snapcraft.io/helm>

```bash
sudo snap install helm --classic
```

## Instale o Lens

Lens é o IDE Kubernetes mais poderoso do mercado.

<https://k8slens.dev/>

<https://snapcraft.io/kontena-lens>

```bash
sudo snap install kontena-lens --classic
```

Ou para a versão mais recente.

```bash
cd /tmp
VERSION=`curl -s https://api.github.com/repos/lensapp/lens/releases/latest | grep "tag_name" | cut -f 2 -d "v" | sed 's/",//g'`
PUBLISHED=`curl -s https://api.github.com/repos/lensapp/lens/releases/latest | grep "published_at" | cut -f 2 -d ":" | cut -f 1 -d "T" | sed -e 's/ "//g' -e 's/-//g'`
wget -c https://lens-binaries.s3-eu-west-1.amazonaws.com/ide/Lens-$VERSION-latest.$PUBLISHED.1.amd64.snap
sudo snap install Lens-$VERSION-latest.$PUBLISHED.1.amd64.snap --dangerous --classic
```

## Instale o Kubenav

kubenav é o navegador para seus clusters Kubernetes diretamente no seu bolso. kubenav é um aplicativo móvel, desktop e web para gerenciar clusters Kubernetes e obter uma visão geral do status de seus recursos.

<https://docs.kubenav.io/>

<https://docs.kubenav.io/desktop/getting-started/>

```bash
cd /tmp
wget -c https://github.com/kubenav/kubenav/releases/latest/download/kubenav-linux-amd64.zip
unzip kubenav-linux-amd64.zip
chmod a+x kubenav
sudo mv kubenav /usr/local/sbin/
```

## Instale o Terraform

Construa, altere e destrua a infraestrutura com o Terraform.

<https://learn.hashicorp.com/terraform>

<https://learn.hashicorp.com/tutorials/terraform/install-cli>

```bash
curl -fsSL 'https://apt.releases.hashicorp.com/gpg' | sudo apt-key add -
echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/hashicorp.list
sudo apt update --fix-missing
sudo apt -y install terraform
```

## Instale o Terraform-Docs

Gere documentação de módulos Terraform em vários formatos.

<https://terraform-docs.io/>

<https://terraform-docs.io/user-guide/installation/>

```bash
cd /tmp
LATEST=`curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | jq '.assets | .[] | .browser_download_url' | grep "linux-amd64" | sed 's/"//g'`
wget -c $LATEST -O "terraform-docs.tar.gz"
tar -xzf terraform-docs.tar.gz
chmod a+x terraform-docs
sudo mv terraform-docs /usr/local/sbin/
```

## Instale o Terrascan

Terrascan é um analisador de código estático para Terraform, detecta violações de conformidade e segurança em Infraestrutura como Código.

<https://runterrascan.io/>

<https://runterrascan.io/docs/getting-started/>

```bash
cd /tmp
LATEST=`curl -s https://api.github.com/repos/accurics/terrascan/releases/latest | jq '.assets | .[] | .browser_download_url' | grep "Linux_x86_64" | sed 's/"//g'`
wget -c $LATEST -O "terrascan.tar.gz"
tar -xzf terrascan.tar.gz
sudo install terrascan /usr/local/bin && rm terrascan
```

## Instale o AWScli

Interface de linha de comando oficial da Amazon AWS.

<https://aws.amazon.com/cli/>

<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

```bash
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo sh aws/install
```

## Instale o Azure-cli

Interface de linha de comando oficial do Azure.

<https://docs.microsoft.com/cli/azure/overview>

<https://docs.microsoft.com/pt-br/cli/azure/install-azure-cli>

```bash
curl -fsSL 'https://packages.microsoft.com/keys/microsoft.asc' | sudo apt-key add -
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/azure-cli.list
sudo apt update --fix-missing
sudo apt -y install azure-cli
```

## Instale o Google Cloud SDK

Interface de linha de comando oficial do Google Cloud.

<https://cloud.google.com/sdk/>

<https://cloud.google.com/sdk/docs/install-sdk>

```bash
curl -fsSL 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
echo "deb [arch=amd64] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update --fix-missing
sudo apt -y install google-cloud-sdk
```

## Instale o Multipass

VMs Ubuntu sob demanda para qualquer estação de trabalho.

<https://multipass.run/>

<https://multipass.run/docs/installing-on-linux>

<https://snapcraft.io/multipass>

```bash
sudo snap install multipass --classic
```

## Instale o Docker

Construa e execute imagens de contêiner com o Docker.

<https://www.docker.com/>

<https://snapcraft.io/docker>

```bash
sudo snap install docker --classic
```

```bash
 sudo addgroup --system docker
 sudo adduser $USER docker
 newgrp docker
 sudo snap disable docker
 sudo snap enable docker
```

## Instale o Containerd

Um tempo de execução de contêiner padrão da indústria com ênfase em simplicidade, robustez e portabilidade

<https://containerd.io/>

<https://containerd.io/docs/getting-started/>

```bash
sudo apt -y install containerd
```

```bash
echo "
#CONTAINERD
alias ctr='sudo ctr'" | tee -a ~/.bashrc
```

```bash
echo "
#DOCKER
alias docker='sudo ctr'" | tee -a ~/.bashrc
```

## Instale o Rancher Desktop

Gerenciamento de Kubernetes e Contêineres no Desktop.

<https://rancherdesktop.io/>

<https://docs.rancherdesktop.io/getting-started/installation/>

```bash
[ -r /dev/kvm ] && [ -w /dev/kvm ] || echo 'privilégios insuficientes'
```

```bash
sudo adduser "$USER" kvm
```

```bash
curl -s https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | gpg --dearmor | sudo dd status=none of=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./' | sudo tee -a /etc/apt/sources.list.d/isv-rancher-stable.list
sudo apt update --fix-missing
sudo apt -y install rancher-desktop
```

## Instale o Powerline

Powerline é um plugin de linha de status para o vim e fornece linhas de status e prompts para vários outros aplicativos.

<https://github.com/powerline/powerline>

<https://powerline.readthedocs.io/en/latest/installation.html>

```bash
sudo apt -y install powerline
```

```bash
 echo '
#POWERLINE
if [ -f `which powerline-daemon` ]; then
  powerline-daemon --quiet --replace
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bindings/bash/powerline.sh
fi' | sudo tee -a /etc/bash.bashrc
```

```bash
source /etc/bash.bashrc
```
