*Read this in other languages: [en-US](README.md), [pt-BR](README.pt-BR.md)*

# WSL + Ubuntu

## O jeito **simples** e o jeito **divertido**

## Habilite a Plataforma de Máquina Virtual

```pwsh
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

## Habilite o Subsistema Windows para Linux

```pwsh
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

## Atualize o Subsistema Windows para Linux

```pwsh
powershell Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile WSLUpdate.msi -UseBasicParsing
```

OU

```pwsh
curl.exe -L -o WSLUpdate.msi https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
```

```pwsh
msiexec.exe /package WSLUpdate.msi /quiet
```

## Defina a Versão Padrão

```pwsh
wsl --set-default-version 2
```

<details>
<summary><b>Se você quer apenas instalar o Linux no Windows com WSL, siga este link e os passos abaixo.</b></summary>

<https://learn.microsoft.com/pt-br/windows/wsl/install>

```pwsh
wsl --list --online
```

```text
A lista a seguir é de distribuições válidas que podem ser instaladas.
Instale usando "wsl --install -d <Distro>".

NOME            NOME AMIGÁVEL
Ubuntu          Ubuntu
Debian          Debian GNU/Linux
kali-linux      Kali Linux Rolling
openSUSE-42     openSUSE Leap 42
SLES-12         SUSE Linux Enterprise Server v12
Ubuntu-16.04    Ubuntu 16.04 LTS
Ubuntu-18.04    Ubuntu 18.04 LTS
Ubuntu-20.04    Ubuntu 20.04 LTS
```

```pwsh
wsl --install -d Ubuntu
```

```pwsh
wsl --setdefault Ubuntu
wsl
```

</details>

<details>
<summary><b>Se você quer ter um maior grau de controle e aprender coisas novas, siga o resto deste artigo.</b></summary>

## Baixe e Importe o Ubuntu 20.04

<details>
<summary><b>Usando Imagens ROOTFS do Canonical WSL</b></summary>

- **Crie uma Pasta para o ROOTFS**

```pwsh
mkdir Ubuntu\Focal\Ubuntu-20.04
```

- **Baixe a Imagem ROOTFS para o WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz -OutFile Ubuntu\Focal\Ubuntu-20.04.tar.gz -UseBasicParsing
```

OU

```pwsh
curl.exe -L -o Ubuntu\Focal\Ubuntu-20.04.tar.gz https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz
```

- **Importe a Imagem ROOTFS para o WSL**

```pwsh
wsl --import Ubuntu-20.04 Ubuntu\Focal\Ubuntu-20.04 Ubuntu\Focal\Ubuntu-20.04.tar.gz
```

- **Liste as Distribuições**

```pwsh
wsl --list --all
```

- **Defina a Distribuição Padrão**

```pwsh
wsl --setdefault Ubuntu-20.04
```

- **Liste Todas as Distribuições e Versões**

```pwsh
wsl --list --all
```

- **Execute a Distribuição**

```pwsh
wsl --distribution Ubuntu-20.04
```

OU

```pwsh
wsl
```

</details>

<details>
<summary><b>Usando Imagens do Microsoft Store WSL</b></summary>

- **Crie uma Pasta para o ROOTFS**

```pwsh
mkdir Ubuntu\Focal\Ubuntu-20.04
mkdir Ubuntu\Focal\ubuntu_focal
```

- **Baixe a Imagem para o WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu\Focal\ubuntu_focal\ubuntu-2004.appx -UseBasicParsing
```

OU

```pwsh
curl.exe -L -o Ubuntu\Focal\ubuntu_focal\ubuntu-2004.appx https://aka.ms/wslubuntu2004
```

- **Instale o 7-Zip**

```cmd
curl.exe -L -o Downloads\7z.exe https://www.7-zip.org/a/7z2201-x64.exe
Downloads\7z.exe /S
```

- **Extraia a Imagem**

```pwsh
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Focal\ubuntu_focal\ubuntu-2004.appx -oUbuntu\Focal\ubuntu_focal\ *_x64.appx
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Focal\ubuntu_focal\Ubuntu_2004.*_x64.appx -oUbuntu\Focal\ubuntu_focal\ install.tar.gz
```

- **Importe a Imagem ROOTFS para o WSL**

```pwsh
wsl --import Ubuntu-20.04 Ubuntu\Focal\Ubuntu-20.04 Ubuntu\Focal\ubuntu_focal\install.tar.gz
```

- **Liste as Distribuições**

```pwsh
wsl --list --all
```

- **Defina a Distribuição Padrão**

```pwsh
wsl --setdefault Ubuntu-20.04
```

- **Liste Todas as Distribuições e Versões**

```pwsh
wsl --list --all
```

- **Execute a Distribuição**

```pwsh
wsl --distribution Ubuntu-20.04
```

OU

```pwsh
wsl
```

</details>

## Baixe e Importe o Ubuntu 22.04

<details>
<summary><b>Usando Imagens ROOTFS do Canonical WSL</b></summary>

- **Crie uma Pasta para o ROOTFS**

```pwsh
mkdir Ubuntu\Jammy\Ubuntu-22.04
```

- **Baixe a Imagem ROOTFS para o WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-wsl.rootfs.tar.gz -OutFile Ubuntu\Jammy\Ubuntu-22.04.tar.gz -UseBasicParsing
```

OU

```pwsh
curl.exe -L -o Ubuntu\Jammy\Ubuntu-22.04.tar.gz https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-wsl.rootfs.tar.gz
```

- **Importe a Imagem ROOTFS para o WSL**

```pwsh
wsl --import Ubuntu-22.04 Ubuntu\Jammy\Ubuntu-22.04 Ubuntu\Jammy\Ubuntu-22.04.tar.gz
```

- **Liste as Distribuições**

```pwsh
wsl --list --all
```

- **Defina a Distribuição Padrão**

```pwsh
wsl --setdefault Ubuntu-22.04
```

- **Liste Todas as Distribuições e Versões**

```pwsh
wsl --list --all
```

- **Execute a Distribuição**

```pwsh
wsl --distribution Ubuntu-22.04
```

OU

```pwsh
wsl
```

</details>

<details>
<summary><b>Usando Imagens do Microsoft Store WSL</b></summary>

- **Crie uma Pasta para o ROOTFS**

```pwsh
mkdir Ubuntu\Jammy\Ubuntu-22.04
mkdir Ubuntu\Jammy\ubuntu_jammy
```

- **Baixe a Imagem para o WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://aka.ms/wslubuntu2204 -OutFile Ubuntu\Jammy\ubuntu_jammy\ubuntu-2204.appx -UseBasicParsing
```

OU

```pwsh
curl.exe -L -o Ubuntu\Jammy\ubuntu_jammy\ubuntu-2204.appx https://aka.ms/wslubuntu2204
```

- **Instale o 7-Zip**

```cmd
curl.exe -L -o Downloads\7z.exe https://www.7-zip.org/a/7z2201-x64.exe
Downloads\7z.exe /S
```

- **Extraia a Imagem**

```pwsh
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Jammy\ubuntu_jammy\ubuntu-2204.appx -oUbuntu\Jammy\ubuntu_jammy\ *_x64.appx
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Jammy\ubuntu_jammy\Ubuntu_2204.*_x64.appx -oUbuntu\Jammy\ubuntu_jammy\ install.tar.gz
```

- **Importe a Imagem ROOTFS para o WSL**

```pwsh
wsl --import Ubuntu-22.04 Ubuntu\Jammy\Ubuntu-22.04 Ubuntu\Jammy\ubuntu_jammy\install.tar.gz
```

- **Liste as Distribuições**

```pwsh
wsl --list --all
```

- **Defina a Distribuição Padrão**

```pwsh
wsl --setdefault Ubuntu-22.04
```

- **Liste Todas as Distribuições e Versões**

```pwsh
wsl --list --all
```

- **Execute a Distribuição**

```pwsh
wsl --distribution Ubuntu-22.04
```

OU

```pwsh
wsl
```

</details>

### Crie um Nome de Usuário

```bash
clear ; echo "Escolha seu nome de usuário!" ; echo -n "Digite o nome de usuário! " ; read username &&
adduser $username &&
addgroup $username adm &&
addgroup $username sudo &&
echo "$username    ALL=(ALL)       NOPASSWD:ALL" | tee -a /etc/sudoers &&
echo "[user]
default = $username" | tee /etc/wsl.conf
```

Saia do WSL e execute o comando abaixo para encerrar a distribuição especificada, após o qual o usuário criado será automaticamente acionado na inicialização.

- **Para Ubuntu-20.04**

```pwsh
wsl --terminate Ubuntu-20.04
wsl --distribution Ubuntu-20.04
```

- **Para Ubuntu-22.04**

```pwsh
wsl --terminate Ubuntu-22.04
wsl --distribution Ubuntu-22.04
```

### Fontes

```bash
clear ; echo "#ubuntu
deb http://archive.ubuntu.com/ubuntu `lsb_release -cs` main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu `lsb_release -cs`-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu `lsb_release -cs`-backports main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu `lsb_release -cs`-proposed restricted main universe multiverse
#security
deb http://security.ubuntu.com/ubuntu `lsb_release -cs`-security main restricted universe multiverse
#partner
deb http://archive.canonical.com/ubuntu `lsb_release -cs` partner" | sudo tee /etc/apt/sources.list
```

```bash
clear ; echo '#!/bin/bash
sudo apt update --fix-missing
sudo apt -y dist-upgrade --download-only
sudo apt -y dist-upgrade
sudo apt -y autoremove
sudo apt -y clean' | sudo tee /usr/local/sbin/updateme
sudo chmod a+x /usr/local/sbin/updateme
```

```bash
updateme
```

### Instale o Powerline

```bash
sudo apt -y install powerline
```

```bash
clear ; echo '
#POWERLINE
if [ -f `which powerline-daemon` ]; then
  powerline-daemon --quiet
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bindings/bash/powerline.sh
fi' | sudo tee -a /etc/bash.bashrc
```

```bash
source /etc/bash.bashrc
```

Para uma melhor experiência de console no Windows, use uma fonte de texto como **Hack**:

<https://github.com/source-foundry/Hack>

<https://github.com/source-foundry/Hack#windows>

Execute os comandos abaixo no CMD para instalar facilmente no Windows:

```pwsh
curl.exe -L -o Downloads\Hack.exe https://github.com/source-foundry/Hack-windows-installer/releases/download/v1.6.0/HackFontsWindowsInstaller.exe
```

```pwsh
Downloads\Hack.exe /SILENT
```

### Homebrew (Opcional)

<https://docs.brew.sh/Homebrew-on-Linux#install>

```bash
sudo apt -y install build-essential procps curl file git
```

```bash
git config --global http.sslVerify false
```

```bash
echo "insecure" | sudo tee $HOME/.curlrc
echo "insecure" | sudo tee /root/.curlrc
```

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

```bash
clear ; echo '
# Defina PATH, MANPATH, etc., para o Homebrew.
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' | sudo tee -a /etc/profile
```

```bash
clear ; echo "
#HOMEBREW
export HOMEBREW_CURLRC=1
export HOMEBREW_FORCE_BREWED_CURL=1
alias brew='HOMEBREW_FORCE_BREWED_CURL=1 ; brew'" | sudo tee -a /etc/bash.bashrc
```

```bash
brew install kubectl
brew install helm
brew install terraform
brew install awscli
```

**Fontes:**

<https://learn.microsoft.com/pt-br/windows/wsl>

<https://docs.microsoft.com/pt-br/windows/wsl/install-win10>

<https://docs.microsoft.com/pt-br/windows/wsl/install-manual>

<https://learn.microsoft.com/pt-br/windows/wsl/install-manual#downloading-distributions>

<https://wiki.ubuntu.com/WSL>

</details>
