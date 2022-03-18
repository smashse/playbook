# Install Homebrew

Homebrew is a free and open-source package management system for Mac OS X.

<https://brew.sh/>

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Change default shell to bash

```bash
chsh -s /bin/bash
```

## Install XCode

```bash
brew install xcodegen
xcode-select --install
```

## Install Python

```bash
brew install python
```

## Install Firefox ESR

Firefox for your enterprise.

<https://www.mozilla.org/pt-BR/firefox/enterprise/>

<https://formulae.brew.sh/cask/firefox>

```bash
brew install --cask homebrew/cask-versions/firefox-esr
```

## Install Google Chrome

The browser built by Google.

<https://www.google.com/intl/pt-BR/chrome/>

<https://chromeenterprise.google/browser/>

<https://formulae.brew.sh/cask/google-chrome>

```bash
brew install --cask google-chrome
```

## Install VSCodium

VSCodium is a community-driven, freely-licensed binary distribution of Microsoft’s editor VS Code.

<https://vscodium.com/#intro>

<https://formulae.brew.sh/cask/vscodium>

```bash
brew install --cask vscodium
```

## Install Visual Studio Code

Visual Studio Code is a lightweight but powerful source code editor which runs on your desktop.

<https://code.visualstudio.com/>

<https://formulae.brew.sh/cask/visual-studio-code>

```bash
brew install --cask visual-studio-code
```

## Install Kubectl

The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters.

<https://kubernetes.io/docs/tasks/tools/>

<https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos>

```bash
brew install kubectl
```

### Install Krew and Neat

#### Krew

Krew is the plugin manager for kubectl command-line tool.

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

Clean up Kubernetes yaml and json output to make it readable.

<https://github.com/itaysk/kubectl-neat>

<https://github.com/itaysk/kubectl-neat#installation>

```bash
kubectl krew install neat
```

## Install Helm

Helm is the best way to find, share, and use software built for Kubernetes.

<https://helm.sh/>

<https://helm.sh/docs/intro/install/#from-homebrew-macos>

```bash
brew install helm
```

## Install Lens

Lens is the most powerful Kubernetes IDE on the market.

<https://k8slens.dev/>

```bash
brew install lens
```

## Install Kubenav

kubenav is the navigator for your Kubernetes clusters right in your pocket. kubenav is a mobile, desktop and web app to manage Kubernetes clusters and to get an overview of the status of your resources.

<https://docs.kubenav.io/>

<https://docs.kubenav.io/desktop/getting-started/>

```bash
brew install kubenav
```

## Install Terraform

Build, change, and destroy infrastructure with Terraform.

<https://learn.hashicorp.com/terraform>

<https://learn.hashicorp.com/tutorials/terraform/install-cli>

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Install Terraform-Docs

Generate Terraform modules documentation in various formats.

<https://terraform-docs.io/>

<https://terraform-docs.io/user-guide/installation/#homebrew>

```bash
brew tap terraform-docs/tap
brew install terraform-docs/tap/terraform-docs
```

## Install AWScli

Official Amazon AWS command-line interface.

<https://aws.amazon.com/cli/>

<https://formulae.brew.sh/formula/awscli>

```bash
brew install awscli
```

## Install Azure-cli

Official Azure command-line interface.

<https://docs.microsoft.com/cli/azure/overview>

<https://formulae.brew.sh/formula/azure-cli>

```bash
brew install azure-cli
```

## Install Google Cloud SDK

Official Google Cloud command-line interface.

<https://cloud.google.com/sdk/>

<https://formulae.brew.sh/cask/google-cloud-sdk>

```bash
brew install --cask google-cloud-sdk
```

## Install Multipass

Ubuntu VMs on demand for any workstation.

<https://multipass.run/>

<https://multipass.run/docs/installing-on-macos>

<https://formulae.brew.sh/cask/multipass>

```bash
brew install --cask multipass
```

## Install Podman

Manage pods, containers, and container images.

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

## Install Rancher Desktop

Kubernetes and Container Management on the Desktop.

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

```bash
echo "
#DOCKER
alias docker='podman'" | tee -a ~/.bashrc
```

```bash
source ~/.bashrc
```

## Install ITerm2

Terminal emulator as alternative to Apple's Terminal app.

<https://www.iterm2.com/>

<https://formulae.brew.sh/cask/iterm2>

```bash
brew install --cask iterm2
```

## Install Powerline-Go

Beautiful and useful low-latency prompt for your shell.

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

Install the PowerlineSymbols font from:

<https://github.com/powerline/powerline/tree/develop/font>

In ITerm2 Preferences, go to "Text", "Font" and enable "Use a different font for non-ASCII text" and then select "PowerlineSymbols" as "Non-ASCII Font".
