# Installing snapd

Snaps can be used on all major Linux distributions, including Ubuntu, Linux Mint, Debian and Fedora.

Snap is pre-installed on most systems based in Ubuntu. Installation instructions can be found at the link below for distributions without pre-installed snap.

<https://snapcraft.io/docs/installing-snapd>

Installation of programs to setup the environment.

```bash
sudo apt -y install curl jq unzip
```

## Install Firefox ESR

Firefox for your enterprise.

<https://www.mozilla.org/pt-BR/firefox/enterprise/>

<https://snapcraft.io/firefox>

```bash
sudo snap install firefox --channel=esr/stable
```

## Install Google Chrome

The browser built by Google.

<https://www.google.com/intl/pt-BR/chrome/>

<https://chromeenterprise.google/browser/>

<https://www.google.com/linuxrepositories/>

```bash
curl -fsSL 'https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb stable main" | sudo tee -a /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update --fix-missing
sudo apt -y install google-chrome-stable
```

## Install VSCodium

VSCodium is a community-driven, freely-licensed binary distribution of Microsoft’s editor VS Code.

<https://vscodium.com/#intro>

<https://snapcraft.io/codium>

```bash
sudo snap install codium --classic
```

## Install Visual Studio Code

Visual Studio Code is a lightweight but powerful source code editor which runs on your desktop.

<https://code.visualstudio.com/>

<https://snapcraft.io/code>

```bash
sudo snap install code --classic
```

## Install Kubectl

The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters.

<https://kubernetes.io/docs/tasks/tools/>

<https://snapcraft.io/kubectl>

```bash
sudo snap install kubectl --classic
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
echo "
#KREW
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" | tee -a ~/.bashrc
```

```bash
source ~/.bashrc
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

<https://snapcraft.io/helm>

```bash
sudo snap install helm --classic
```

## Install Lens

Lens is the most powerful Kubernetes IDE on the market.

<https://k8slens.dev/>

<https://snapcraft.io/kontena-lens>

```bash
sudo snap install kontena-lens --classic
```

Or for the latest release.

```bash
cd /tmp
VERSION=`curl -s https://api.github.com/repos/lensapp/lens/releases/latest | grep "tag_name" | cut -f 2 -d "v" | sed 's/",//g'`
PUBLISHED=`curl -s https://api.github.com/repos/lensapp/lens/releases/latest | grep "published_at" | cut -f 2 -d ":" | cut -f 1 -d "T" | sed -e 's/ "//g' -e 's/-//g'`
wget -c https://lens-binaries.s3-eu-west-1.amazonaws.com/ide/Lens-$VERSION-latest.$PUBLISHED.1.amd64.snap
sudo snap install Lens-$VERSION-latest.$PUBLISHED.1.amd64.snap --dangerous --classic
```

## Install Kubenav

kubenav is the navigator for your Kubernetes clusters right in your pocket. kubenav is a mobile, desktop and web app to manage Kubernetes clusters and to get an overview of the status of your resources.

<https://docs.kubenav.io/>

<https://docs.kubenav.io/desktop/getting-started/>

```bash
cd /tmp
wget -c https://github.com/kubenav/kubenav/releases/latest/download/kubenav-linux-amd64.zip
unzip kubenav-linux-amd64.zip
chmod a+x kubenav
sudo mv kubenav /usr/local/sbin/
```

## Install Terraform

Build, change, and destroy infrastructure with Terraform.

<https://learn.hashicorp.com/terraform>

<https://learn.hashicorp.com/tutorials/terraform/install-cli>

```bash
curl -fsSL 'https://apt.releases.hashicorp.com/gpg' | sudo apt-key add -
echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/hashicorp.list
sudo apt update --fix-missing
sudo apt -y install terraform
```

## Install Terraform-Docs

Generate Terraform modules documentation in various formats.

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

## Install AWScli

Official Amazon AWS command-line interface.

<https://aws.amazon.com/cli/>

<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

```bash
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo sh aws/install
```

## Install Azure-cli

Official Azure command-line interface.

<https://docs.microsoft.com/cli/azure/overview>

<https://docs.microsoft.com/pt-br/cli/azure/install-azure-cli>

```bash
curl -fsSL 'https://packages.microsoft.com/keys/microsoft.asc' | sudo apt-key add -
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/azure-cli.list
sudo apt update --fix-missing
sudo apt -y install azure-cli
```

## Install Google Cloud SDK

Official Google Cloud command-line interface.

<https://cloud.google.com/sdk/>

<https://cloud.google.com/sdk/docs/install-sdk>

```bash
curl -fsSL 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
echo "deb [arch=amd64] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update --fix-missing
sudo apt -y install google-cloud-sdk
```

## Install Multipass

Ubuntu VMs on demand for any workstation.

<https://multipass.run/>

<https://multipass.run/docs/installing-on-linux>

<https://snapcraft.io/multipass>

```bash
sudo snap install multipass --classic
```

## Install Docker

Build and run container images with Docker.

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

## Install Containerd

An industry-standard container runtime with an emphasis on simplicity, robustness and portability

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

## Install Rancher Desktop

Kubernetes and Container Management on the Desktop.

<https://rancherdesktop.io/>

<https://docs.rancherdesktop.io/getting-started/installation/>

```bash
[ -r /dev/kvm ] && [ -w /dev/kvm ] || echo 'insufficient privileges'
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

## Install Powerline

Powerline is a statusline plugin for vim, and provides statuslines and prompts for several other applications.

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
