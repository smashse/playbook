*Read this in other languages: [en-US](MACENV.md), [pt-BR](MACENV.pt-BR.md)*

# Instale o Homebrew

Homebrew é um sistema de gerenciamento de pacotes gratuito e de código aberto para Mac OS X.

<https://brew.sh/>

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Altere o shell padrão para bash

```bash
chsh -s /bin/bash
```

## Instale o XCode

```bash
brew install xcodegen
xcode-select --install
```

## Instale o Python

```bash
brew install python
```

## Instale o Firefox ESR

Firefox para sua empresa.

<https://www.mozilla.org/pt-BR/firefox/enterprise/>

<https://formulae.brew.sh/cask/firefox>

```bash
brew install --cask homebrew/cask-versions/firefox-esr
```

## Instale o Google Chrome

O navegador construído pelo Google.

<https://www.google.com/intl/pt-BR/chrome/>

<https://chromeenterprise.google/browser/>

<https://formulae.brew.sh/cask/google-chrome>

```bash
brew install --cask google-chrome
```

## Instale o VSCodium

VSCodium é uma distribuição binária do editor VS Code da Microsoft, orientada pela comunidade e com licença livre.

<https://vscodium.com/#intro>

<https://formulae.brew.sh/cask/vscodium>

```bash
brew install --cask vscodium
```

## Instale o Visual Studio Code

Visual Studio Code é um editor de código fonte leve, mas poderoso, que roda no seu desktop.

<https://code.visualstudio.com/>

<https://formulae.brew.sh/cask/visual-studio-code>

```bash
brew install --cask visual-studio-code
```

## Instale o Kubectl

A ferramenta de linha de comando do Kubernetes, kubectl, permite que você execute comandos em clusters Kubernetes.

<https://kubernetes.io/docs/tasks/tools/>

<https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos>

```bash
brew install kubectl
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
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
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

<https://helm.sh/docs/intro/install/#from-homebrew-macos>

```bash
brew install helm
```

## Instale o Lens

Lens é o IDE Kubernetes mais poderoso do mercado.

<https://k8slens.dev/>

```bash
brew install lens
```

## Instale o Kubenav

kubenav é o navegador para seus clusters Kubernetes diretamente no seu bolso. kubenav é um aplicativo móvel, desktop e web para gerenciar clusters Kubernetes e obter uma visão geral do status de seus recursos.

<https://docs.kubenav.io/>

<https://docs.kubenav.io/desktop/getting-started/>

```bash
brew install kubenav
```

## Instale o Terraform

Construa, altere e destrua a infraestrutura com o Terraform.

<https://learn.hashicorp.com/terraform>

<https://learn.hashicorp.com/tutorials/terraform/install-cli>

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Instale o Terraform-Docs

Gere documentação de módulos Terraform em vários formatos.

<https://terraform-docs.io/>

<https://terraform-docs.io/user-guide/installation/#homebrew>

```bash
brew tap terraform-docs/tap
brew install terraform-docs/tap/terraform-docs
```

## Instale o Terrascan

Terrascan é um analisador de código estático para Terraform, detecta violações de conformidade e segurança em Infraestrutura como Código.

<https://runterrascan.io/>

<https://formulae.brew.sh/formula/terrascan>

```bash
brew install terrascan
```

## Instale o AWScli

Interface de linha de comando oficial da Amazon AWS.

<https://aws.amazon.com/cli/>

<https://formulae.brew.sh/formula/awscli>

```bash
brew install awscli
```

## Instale o Azure-cli

Interface de linha de comando oficial do Azure.

<https://docs.microsoft.com/cli/azure/overview>

<https://formulae.brew.sh/formula/azure-cli>

```bash
brew install azure-cli
```

## Instale o Google Cloud SDK

Interface de linha de comando oficial do Google Cloud.

<https://cloud.google.com/sdk/>

<https://formulae.brew.sh/cask/google-cloud-sdk>

```bash
brew install --cask google-cloud-sdk
```

## Instale o Multipass

VMs Ubuntu sob demanda para qualquer estação de trabalho.

<https://multipass.run/>

<https://multipass.run/docs/installing-on-macos>

<https://formulae.brew.sh/cask/multipass>

```bash
brew install --cask multipass
```

## Instale o Podman

Gerencie pods, contêineres e imagens de contêiner.

<https://podman.io/>

<https://podman.io/getting-started/installation>

```bash
brew install podman
```

```bash
podman machine init
podman machine start
podman info
```

```bash
echo "
#DOCKER
alias docker='podman'" | tee -a ~/.bashrc
```

```bash
source ~/.bashrc
```

## Instale o Rancher Desktop

Gerenciamento de Kubernetes e Contêineres no Desktop.

<https://rancherdesktop.io/>

<https://iongion.github.io/podman-desktop-companion/>

```bash
for i in $(curl -s https://api.github.com/repos/rancher-sandbox/rancher-desktop/releases/latest | grep 'browser_' | cut -d\" -f4 | grep "x86_64.dmg" | head -1); do wget -c $i -O "rancher_desktop.dmg"; done
```

```bash
cd /tmp
hdiutil attach rancher_desktop.dmg -mountpoint /Volumes/Rancher
cp -a /Volumes/Rancher/Rancher*.app /Volumes/Rancher/Applications/
umount /Volumes/Rancher
```

## Instale o ITerm2

Emulador de terminal como alternativa ao aplicativo Terminal da Apple.

<https://www.iterm2.com/>

<https://formulae.brew.sh/cask/iterm2>

```bash
brew install --cask iterm2
```

## Instale o Powerline-Go

Prompt bonito e útil de baixa latência para o seu shell.

<https://github.com/justjanne/powerline-go>

<https://formulae.brew.sh/formula/powerline-go>

```bash
brew install powerline-go
```

```bash
echo '
#POWERLINE
function _update_ps1() {
    PS1="$($GOPATH/bin/powerline-go -error $? -jobs $(jobs -p | wc -l))"
}

if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi' | tee -a ~/.profile
```

```bash
source ~/.profile
```

Instale a fonte PowerlineSymbols em:

<https://github.com/powerline/powerline/tree/develop/font>

Nas Preferências do ITerm2, vá para "Texto", "Fonte" e habilite "Usar uma fonte diferente para texto não ASCII" e então selecione "PowerlineSymbols" como "Fonte não ASCII".
