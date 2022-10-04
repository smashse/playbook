# WSL + Ubuntu

## The **simple** way and the **fun** way

## Enable Virtual Machine Platform

```pwsh
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

## Enable Windows Subsystem Linux

```pwsh
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

## Update Windows Subsystem Linux

```pwsh
powershell Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile WSLUpdate.msi -UseBasicParsing
```

OR

```pwsh
curl.exe -L -o WSLUpdate.msi https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
```

```pwsh
msiexec.exe /package WSLUpdate.msi /quiet
```

## Set Default Version

```pwsh
wsl --set-default-version 2
```

<details>
<summary><b>If you just want to install Linux on Windows with WSL, follow this link and the steps below.</b></summary>

<https://learn.microsoft.com/en-us/windows/wsl/install>

```pwsh
wsl --list --online
```

```text
The following is a list of valid distributions that can be installed.
Install using "wsl --install -d <Distro>".

NAME            FRIENDLY NAME
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
<summary><b>If you want to have a higher degree of control and learn new things, follow the rest of this article.</b></summary>

## Download And Import Ubuntu 20.04

<details>
<summary><b>Using Canonical WSL ROOTFS Images</b></summary>

- **Create Folder For ROOTFS**

```pwsh
mkdir Ubuntu\Focal\Ubuntu-20.04
```

- **Download ROOTFS Image For WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz -OutFile Ubuntu\Focal\Ubuntu-20.04.tar.gz -UseBasicParsing
```

OR

```pwsh
curl.exe -L -o Ubuntu\Focal\Ubuntu-20.04.tar.gz https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz
```

- **Import ROOTFS Image For WSL**

```pwsh
wsl --import Ubuntu-20.04 Ubuntu\Focal\Ubuntu-20.04 Ubuntu\Focal\Ubuntu-20.04.tar.gz
```

- **List Distributions**

```pwsh
wsl --list --all
```

- **Set Default Distribution**

```pwsh
wsl --setdefault Ubuntu-20.04
```

- **List All Distributions And Version**

```pwsh
wsl --list --all
```

- **Run Distribution**

```pwsh
wsl --distribution Ubuntu-20.04
```

OR

```pwsh
wsl
```

</details>

<details>
<summary><b>Using Microsoft Store WSL Images</b></summary>

- **Create Folder For ROOTFS**

```pwsh
mkdir Ubuntu\Focal\Ubuntu-20.04
mkdir Ubuntu\Focal\ubuntu_focal
```

- **Download Image For WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu\Focal\ubuntu_focal\ubuntu-2004.appx -UseBasicParsing
```

OR

```pwsh
curl.exe -L -o Ubuntu\Focal\ubuntu_focal\ubuntu-2004.appx https://aka.ms/wslubuntu2004
```

- **Install 7-Zip**

```cmd
curl.exe -L -o Downloads\7z.exe https://www.7-zip.org/a/7z2201-x64.exe
Downloads\7z.exe /S
```

- **Extract Image**

```pwsh
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Focal\ubuntu_focal\ubuntu-2004.appx -oUbuntu\Focal\ubuntu_focal\ *_x64.appx
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Focal\ubuntu_focal\Ubuntu_2004.*_x64.appx -oUbuntu\Focal\ubuntu_focal\ install.tar.gz
```

- **Import ROOTFS Image For WSL**

```pwsh
wsl --import Ubuntu-20.04 Ubuntu\Focal\Ubuntu-20.04 Ubuntu\Focal\ubuntu_focal\install.tar.gz
```

- **List Distributions**

```pwsh
wsl --list --all
```

- **Set Default Distribution**

```pwsh
wsl --setdefault Ubuntu-20.04
```

- **List All Distributions And Version**

```pwsh
wsl --list --all
```

- **Run Distribution**

```pwsh
wsl --distribution Ubuntu-20.04
```

OR

```pwsh
wsl
```

</details>

## Download And Import Ubuntu 22.04

<details>
<summary><b>Using Canonical WSL ROOTFS Images</b></summary>

- **Create Folder For ROOTFS**

```pwsh
mkdir Ubuntu\Jammy\Ubuntu-22.04
```

- **Download ROOTFS Image For WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-wsl.rootfs.tar.gz -OutFile Ubuntu\Jammy\Ubuntu-22.04.tar.gz -UseBasicParsing
```

OR

```pwsh
curl.exe -L -o Ubuntu\Jammy\Ubuntu-22.04.tar.gz https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-wsl.rootfs.tar.gz
```

- **Import ROOTFS Image For WSL**

```pwsh
wsl --import Ubuntu-22.04 Ubuntu\Jammy\Ubuntu-22.04 Ubuntu\Jammy\Ubuntu-22.04.tar.gz
```

- **List Distributions**

```pwsh
wsl --list --all
```

- **Set Default Distribution**

```pwsh
wsl --setdefault Ubuntu-22.04
```

- **List All Distributions And Version**

```pwsh
wsl --list --all
```

- **Run Distribution**

```pwsh
wsl --distribution Ubuntu-22.04
```

OR

```pwsh
wsl
```

</details>

<details>
<summary><b>Using Microsoft Store WSL Images</b></summary>

- **Create Folder For ROOTFS**

```pwsh
mkdir Ubuntu\Jammy\Ubuntu-22.04
mkdir Ubuntu\Jammy\ubuntu_jammy
```

- **Download Image For WSL**

```pwsh
powershell Invoke-WebRequest -Uri https://aka.ms/wslubuntu2204 -OutFile Ubuntu\Jammy\ubuntu_jammy\ubuntu-2204.appx -UseBasicParsing
```

OR

```pwsh
curl.exe -L -o Ubuntu\Jammy\ubuntu_jammy\ubuntu-2204.appx https://aka.ms/wslubuntu2204
```

- **Install 7-Zip**

```cmd
curl.exe -L -o Downloads\7z.exe https://www.7-zip.org/a/7z2201-x64.exe
Downloads\7z.exe /S
```

- **Extract Image**

```pwsh
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Jammy\ubuntu_jammy\ubuntu-2204.appx -oUbuntu\Jammy\ubuntu_jammy\ *_x64.appx
"C:\Program Files\7-Zip\7z.exe" e Ubuntu\Jammy\ubuntu_jammy\Ubuntu_2204.*_x64.appx -oUbuntu\Jammy\ubuntu_jammy\ install.tar.gz
```

- **Import ROOTFS Image For WSL**

```pwsh
wsl --import Ubuntu-22.04 Ubuntu\Jammy\Ubuntu-22.04 Ubuntu\Jammy\ubuntu_jammy\install.tar.gz
```

- **List Distributions**

```pwsh
wsl --list --all
```

- **Set Default Distribution**

```pwsh
wsl --setdefault Ubuntu-22.04
```

- **List All Distributions And Version**

```pwsh
wsl --list --all
```

- **Run Distribution**

```pwsh
wsl --distribution Ubuntu-22.04
```

OR

```pwsh
wsl
```

</details>

### Create Username

```bash
clear ; echo "Choose your username!" ; echo -n "Type the username! " ; read username &&
adduser $username &&
addgroup $username adm &&
addgroup $username sudo &&
echo "$username    ALL=(ALL)       NOPASSWD:ALL" | tee -a /etc/sudoers &&
echo "[user]
default = $username" | tee /etc/wsl.conf
```

Exit WSL and run the command below to terminate the specified distribution, after which the created user will be automatically triggered at startup.

- **For Ubuntu-20.04**

```pwsh
wsl --terminate Ubuntu-20.04
wsl --distribution Ubuntu-20.04
```

- **For Ubuntu-22.04**

```pwsh
wsl --terminate Ubuntu-22.04
wsl --distribution Ubuntu-22.04
```

### Sources

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

### Install Powerline

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

For a better console experience in Windows, use a text font such as **Hack**:

<https://github.com/source-foundry/Hack>

<https://github.com/source-foundry/Hack#windows>

Run the commands below in the CMD to easily install on Windows:

```pwsh
curl.exe -L -o Downloads\Hack.exe https://github.com/source-foundry/Hack-windows-installer/releases/download/v1.6.0/HackFontsWindowsInstaller.exe
```

```pwsh
Downloads\Hack.exe /SILENT
```

**Sources:**

<https://learn.microsoft.com/en-us/windows/wsl>

<https://docs.microsoft.com/en-us/windows/wsl/install-win10>

<https://docs.microsoft.com/en-us/windows/wsl/install-manual>

<https://learn.microsoft.com/en-us/windows/wsl/install-manual#downloading-distributions>

<https://wiki.ubuntu.com/WSL>

</details>
