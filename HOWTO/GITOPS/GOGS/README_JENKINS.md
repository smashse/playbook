# Requirements for this POC

In this POC we will use Multipass to create instances to install the Gogs and Microk8s, then establishing the Git server as a GitOps for the Kubernetes cluster provisioned with Microk8s.

## Install Multipass

```bash
sudo snap install multipass --classic
```

# MicroK8s

MicroK8s is the smallest, fastest, fully-conformant Kubernetes that tracks upstream releases and makes clustering trivial. MicroK8s is great for offline development, prototyping, and testing.

## Create a MicroK8s template

```bash
echo '#cloud-config
runcmd:
  - apt update --fix-missing
  - snap refresh
  - snap install microk8s --classic
  - microk8s status --wait-ready
  - microk8s enable dns ingress' > cloud-config-microk8s.yaml
```

## Create a MicroK8s instance

```bash
multipass launch focal -n microk8s -c 2 -m 2G -d 10G --cloud-init cloud-config-microk8s.yaml
```

## Export the current MicroK8s configuration for use with Kubectl

### Create the folder to store the configuration of the Kubernetes cluster in the instance

```bash
sudo mkdir -p $HOME/.kube/configs
```

### Export the MicroK8s configuration in the instance to the created folder

```bash
multipass exec microk8s -- sudo microk8s config > $HOME/.kube/configs/config-microk8s
```

### Use in your session the configuration exported as default for use with Kubectl

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

```bash
chmod 0600 $KUBECONFIG
```

### Install Kubectl

```bash
sudo snap install kubectl --classic
```

```bash
kubectl get no
```

```txt
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   59m   v1.21.5-3+83e2bb7ee39726
```

### Add an IP alias of the microk8s instance to microk8s.local

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.local/' | sudo tee -a /etc/hosts
```

### Add an IP alias of the microk8s instance to app01.local, app02.local and app03.local

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     app01.local app02.local app03.local/' | sudo tee -a /etc/hosts
```

### URL for microk8s.local

<http://microk8s.local>

## Install Gogs

# Gogs

Gogs is a painless self-hosted Git service. This project aims to build a simple, stable and extensible self-hosted Git service that can be setup in the most painless way.

## Create a cloud-init for the Gogs instance with Multipass

```bash
echo '#cloud-config
write_files:
  - path: /etc/rc.local
    owner: root:root
    permissions: 0777
    content: |
      #!/bin/bash
      exec sudo /opt/gogs/gogs web &
      exit 0
    append: true
  - path: /opt/gogs/custom/conf/app.ini
    owner: root:root
    permissions: 0777
    content: |
      BRAND_NAME = Gogs
      RUN_USER   = root
      RUN_MODE   = prod

      [database]
      TYPE     = sqlite3
      HOST     = 127.0.0.1:5432
      NAME     = gogs
      USER     = gogs
      PASSWORD =
      SSL_MODE = disable
      PATH     = data/gogs.db

      [repository]
      ROOT = /opt/gogs/gogs-repositories

      [server]
      DOMAIN           = gogs.local
      HTTP_PORT        = 3000
      EXTERNAL_URL     = http://gogs.local:3000/
      DISABLE_SSH      = false
      SSH_PORT         = 2222
      START_SSH_SERVER = true
      OFFLINE_MODE     = false

      [mailer]
      ENABLED = false

      [service]
      REGISTER_EMAIL_CONFIRM = false
      ENABLE_NOTIFY_MAIL     = false
      DISABLE_REGISTRATION   = false
      ENABLE_CAPTCHA         = true
      REQUIRE_SIGNIN_VIEW    = false

      [picture]
      DISABLE_GRAVATAR        = false
      ENABLE_FEDERATED_AVATAR = false

      [session]
      PROVIDER = file

      [log]
      MODE      = console, file
      LEVEL     = Info
      ROOT_PATH = /opt/gogs/log
    append: true
runcmd:
  - apt update --fix-missing
  - apt -y remove snapd --purge
  - cd /tmp
  - wget -c https://dl.gogs.io/0.12.3/gogs_0.12.3_linux_amd64.tar.gz
  - tar -zxvf gogs_0.12.3_linux_amd64.tar.gz
  - mkdir -p /opt/gogs/
  - chmod u+rxw /opt/gogs
  - cp -raf /tmp/gogs/gogs /opt/gogs/
  - chown -R root:root /opt/gogs
  - /opt/gogs/gogs web &' > cloud-config-gogs.yaml
```

## Create Gogs instance with Multipass

```bash
multipass launch focal -n gogs -c 1 -m 1G -d 5G --cloud-init cloud-config-gogs.yaml
```

## Add an IP alias of the Gogs instance to gogs.local

```bash
multipass info gogs | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     gogs.local/' | sudo tee -a /etc/hosts
```

### URL for gogs.local

<http://gogs.local>

![Finish installing Gogs](./img/gogs_000.png "Finish installing Gogs")

## Create **administrator** and **k8s** users

```bash
multipass exec gogs -- sudo /opt/gogs/gogs admin create-user --name administrator --password administrator --admin --email administrator@example.com
```

```bash
multipass exec gogs -- sudo /opt/gogs/gogs admin create-user --name k8s --password k8s --email k8s@example.com
```

## Reboot Gogs

```bash
multipass exec gogs -- sudo reboot
```

## Access Gogs

![Gogs login page](./img/gogs_001.png "Gogs login page")

![Gogs login page with Admin user](./img/gogs_002.png "Gogs login page with Admin user")

## Create a **apps** repository

![Create a repository step 1](./img/gogs_003.png "Create a repository step 1")

![Create a repository step 2](./img/gogs_004.png "Create a repository step 2")

## Add **k8s** user to **apps** repository

![Add k8s user to repository step 1](./img/gogs_005.png "Add k8s user to repository step 1")

![Add k8s user to repository step 2](./img/gogs_006.png "Add k8s user to repository step 2")

![Add k8s user to repository step 3](./img/gogs_007.png "Add k8s user to repository step 3")

## Create a SSH key (Optional)

```bash
ssh-keygen -t ed25519 -C "administrator@example.com" -f ssh-key-gogs
```

## Clone **apps** repository

```bash
git clone http://gogs.local:3000/administrator/apps.git
```

```text
Cloning into 'apps'...
remote: Enumerating objects: 3, done.
remote: Counting objects: 100% (3/3), done.
remote: Total 3 (delta 0), reused 0 (delta 0)
Unpacking objects: 100% (3/3), 217 bytes | 217.00 KiB/s, done.
```

## Create sample apps

```bash
cd apps
mkdir -p apps/{app01,app02,app03}
echo "timestamps {

node () {

	stage ('app03 - Checkout') {
 	 checkout([\$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'k8s', url: 'http://gogs.local:3000/administrator/apps.git']]])
	}
	stage ('app03 - Build') {
 			// Shell build step
sh '''
echo "app03"
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
./kubectl get no
./kubectl apply -f apps/app03/app03_list.yaml
  '''
	}
}
}" > apps/app03/Jenkinsfile
echo 'apiVersion: v1
items:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: app03
  - apiVersion: v1
    data:
      default.conf: |
        server {
            listen       8080;
            listen  [::]:8080;
            server_name  localhost;
            location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
            }
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {
                root   /usr/share/nginx/html;
            }
        }
    kind: ConfigMap
    metadata:
      name: app03-config
      namespace: app03
  - apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: app03-deployment
      name: app03-deployment
      namespace: app03
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: app03-deployment
      strategy:
        rollingUpdate:
          maxSurge: 25%
          maxUnavailable: 25%
        type: RollingUpdate
      template:
        metadata:
          labels:
            app: app03-deployment
        spec:
          containers:
            - image: nginx:stable
              name: app03-pod
              ports:
                - containerPort: 8080
                  protocol: TCP
              volumeMounts:
                - mountPath: /etc/nginx/conf.d
                  name: app03-config
          dnsPolicy: ClusterFirst
          volumes:
            - configMap:
                name: app03-config
              name: app03-config
  - apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: app03-deployment
      name: app03-service
      namespace: app03
    spec:
      ports:
        - port: 8080
      selector:
        app: app03-deployment
      type: NodePort
  - apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: app03-ingress
      namespace: app03
    spec:
      rules:
        - host: app03.local
          http:
            paths:
              - backend:
                  service:
                    name: app03-service
                    port:
                      number: 8080
                path: /
                pathType: Prefix
kind: List
metadata: {}' > apps/app03/app03_list.yaml
echo 'apiVersion: v1
items:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: app02
  - apiVersion: v1
    data:
      default.conf: |
        server {
            listen       8080;
            listen  [::]:8080;
            server_name  localhost;
            location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
            }
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {
                root   /usr/share/nginx/html;
            }
        }
    kind: ConfigMap
    metadata:
      name: app02-config
      namespace: app02
  - apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: app02-deployment
      name: app02-deployment
      namespace: app02
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: app02-deployment
      strategy:
        rollingUpdate:
          maxSurge: 25%
          maxUnavailable: 25%
        type: RollingUpdate
      template:
        metadata:
          labels:
            app: app02-deployment
        spec:
          containers:
            - image: nginx:stable
              name: app02-pod
              ports:
                - containerPort: 8080
                  protocol: TCP
              volumeMounts:
                - mountPath: /etc/nginx/conf.d
                  name: app02-config
          dnsPolicy: ClusterFirst
          volumes:
            - configMap:
                name: app02-config
              name: app02-config
  - apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: app02-deployment
      name: app02-service
      namespace: app02
    spec:
      ports:
        - port: 8080
      selector:
        app: app02-deployment
      type: NodePort
  - apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: app02-ingress
      namespace: app02
    spec:
      rules:
        - host: app02.local
          http:
            paths:
              - backend:
                  service:
                    name: app02-service
                    port:
                      number: 8080
                path: /
                pathType: Prefix
kind: List
metadata: {}' > apps/app02/app02_list.yaml
echo 'apiVersion: v1
items:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: app01
  - apiVersion: v1
    data:
      default.conf: |
        server {
            listen       8080;
            listen  [::]:8080;
            server_name  localhost;
            location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
            }
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {
                root   /usr/share/nginx/html;
            }
        }
    kind: ConfigMap
    metadata:
      name: app01-config
      namespace: app01
  - apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: app01-deployment
      name: app01-deployment
      namespace: app01
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: app01-deployment
      strategy:
        rollingUpdate:
          maxSurge: 25%
          maxUnavailable: 25%
        type: RollingUpdate
      template:
        metadata:
          labels:
            app: app01-deployment
        spec:
          containers:
            - image: nginx:stable
              name: app01-pod
              ports:
                - containerPort: 8080
                  protocol: TCP
              volumeMounts:
                - mountPath: /etc/nginx/conf.d
                  name: app01-config
          dnsPolicy: ClusterFirst
          volumes:
            - configMap:
                name: app01-config
              name: app01-config
  - apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: app01-deployment
      name: app01-service
      namespace: app01
    spec:
      ports:
        - port: 8080
      selector:
        app: app01-deployment
      type: NodePort
  - apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: app01-ingress
      namespace: app01
    spec:
      rules:
        - host: app01.local
          http:
            paths:
              - backend:
                  service:
                    name: app01-service
                    port:
                      number: 8080
                path: /
                pathType: Prefix
kind: List
metadata: {}' > apps/app01/app01_list.yaml
```

```bash
git config --local user.name k8s
git config --local user.email k8s@example.com
git add -A
git commit -m "apps"
```

```text
[master 73c8510] apps
 4 files changed, 301 insertions(+)
 create mode 100644 apps/app01/app01_list.yaml
 create mode 100644 apps/app02/app02_list.yaml
 create mode 100644 apps/app03/Jenkinsfile
 create mode 100644 apps/app03/app03_list.yaml
```

```bash
git push
```

```text
Enumerating objects: 11, done.
Counting objects: 100% (11/11), done.
Delta compression using up to 8 threads
Compressing objects: 100% (8/8), done.
Writing objects: 100% (10/10), 1.76 KiB | 1.76 MiB/s, done.
Total 10 (delta 2), reused 0 (delta 0)
To http://gogs.local:3000/administrator/apps.git
   6428dda..73c8510  master -> master
```

## Install Jenkins

# Jenkins

The leading open source automation server, Jenkins provides hundreds of plugins to support building, deploying and automating any project.

## Create a cloud-init for the Jenkins instance with Multipass

```bash
echo '#cloud-config
write_files:
  - path: /var/lib/jenkins/.kube/config
    owner: jenkins:jenkins
    permissions: 0600
    content: |
      #KUBECONFIG
    append: true
runcmd:
  - apt update --fix-missing
  - apt -y remove snapd --purge
  - sudo echo "deb http://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
  - wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
  - sudo echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment
  - sudo source /etc/environment && source /etc/environment
  - sudo apt update --fix-missing
  - sudo apt -y install openjdk-11-jre-headless sshfs
  - sudo apt -y install jenkins
  - sudo systemctl daemon-reload
  - sudo systemctl start jenkins
  - sudo systemctl status jenkins
  - sudo systemctl enable jenkins.service' > cloud-config-jenkins.yaml
```

## Create Jenkins instance with Multipass

```bash
multipass launch focal -n jenkins -c 1 -m 1G -d 5G --cloud-init cloud-config-jenkins.yaml
```

## Add an IP alias of the Jenkins instance to jenkins.local

```bash
multipass info jenkins | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     jenkins.local/' | sudo tee -a /etc/hosts
```

## Show the initial admin password

```bash
multipass exec jenkins -- sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Copy the Microk8s Kubeconfig to Jenkins

```bash
multipass mount $HOME/.kube/configs/ jenkins:/media
multipass exec jenkins -- sudo cp -raf /media/config-microk8s /var/lib/jenkins/.kube/config
multipass exec jenkins -- sudo chown jenkins: /media/config-microk8s /var/lib/jenkins/.kube/config
multipass exec jenkins -- sudo chmod 0600 /media/config-microk8s /var/lib/jenkins/.kube/config
multipass umount jenkins
```

## Get the Jenkins CLI client

```bash
cd /tmp
wget http://jenkins.local:8080/jnlpJars/jenkins-cli.jar
sudo mkdir -p /usr/local/share/jenkins/
sudo mv jenkins-cli.jar /usr/local/share/jenkins/
alias jenkins-cli='java -jar /usr/local/share/jenkins/jenkins-cli.jar'
```

```bash
jenkins-cli version
```

```text
2.303.2
```

## Check commands supported by the client

```bash
jenkins-cli -s http://jenkins.local:8080/ -auth administrator:administrator help
```

**Or to save server and auth user credentials**

```bash
alias jenkins-cli='java -jar /usr/local/share/jenkins/jenkins-cli.jar -s http://jenkins.local:8080/ -auth administrator:administrator'
```

```bash
jenkins-cli help
```

## Install Kubernetes plugin

Jenkins plugin to run dynamic agents in a Kubernetes cluster.

Kubernetes Plugin: https://plugins.jenkins.io/kubernetes/

```bash
jenkins-cli install-plugin kubernetes
```

### Configuration

Fill in the Kubernetes plugin configuration. In order to do that, you will open the Jenkins UI and navigate to Manage Jenkins -> Manage Nodes and Clouds -> Configure Clouds -> Add a new cloud -> Kubernetes and enter the Kubernetes URL and Jenkins URL appropriately, unless Jenkins is running in Kubernetes in which case the defaults work.

```text
Kubernetes> Name: microk8s-cluster
Kubernetes> Kubernetes URL: https://microk8s.local:16443
Kubernetes> Kubernetes server certificate key> Disable https certificate check: OK
Kubernetes> WebSocket: OK
Kubernetes> Jenkins URL: http://jenkins.local:8080
Save
```

## Manage credentials

### Create a k8s credential to use for Gogs access

```bash
echo '<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>k8s</id>
  <description>k8s</description>
  <username>k8s</username>
  <password>k8s</password>
  <usernameSecret>false</usernameSecret>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>' >k8s_credential.xml
```

```bash
jenkins-cli create-credentials-by-xml system::system::jenkins _ < k8s_credential.xml
```

### List credentials

```bash
jenkins-cli list-credentials system::system::jenkins
```

```text
=================================
Domain           (global)
Description
# of Credentials 1
=================================
Id               Name
================ ================
k8s              k8s/****** (k8s)
=================================
```

### Get XML from k8s credential

```bash
jenkins-cli get-credentials-as-xml system::system::jenkins _ k8s
```

```xml
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl plugin="credentials@2.6.1">
  <scope>GLOBAL</scope>
  <id>k8s</id>
  <description>k8s</description>
  <username>k8s</username>
  <password>
    <secret-redacted/>
  </password>
  <usernameSecret>false</usernameSecret>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
```

## Manage Jobs

### Create job app01

```bash
echo "<?xml version='1.1' encoding='UTF-8'?>
<project>
  <actions />
  <description>app01</description>
  <keepDependencies>false</keepDependencies>
  <properties />
  <scm class='hudson.plugins.git.GitSCM'>
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <name>app01</name>
        <url>http://gogs.local:3000/administrator/apps.git</url>
        <credentialsId>k8s</credentialsId>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
    <branches>
      <hudson.plugins.git.BranchSpec>
        <name>*/master</name>
      </hudson.plugins.git.BranchSpec>
    </branches>
    <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    <submoduleCfg class='empty-list' />
    <extensions />
  </scm>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers>
    <hudson.triggers.SCMTrigger>
      <spec>H/5 * * * *</spec>
      <ignorePostCommitHooks>false</ignorePostCommitHooks>
    </hudson.triggers.SCMTrigger>
  </triggers>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.tasks.Shell>
      <command>echo &quot;app01&quot;
curl -LO &quot;https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl&quot;
chmod +x ./kubectl
./kubectl get no
./kubectl apply -f apps/app01/app01_list.yaml</command>
      <configuredLocalRules />
    </hudson.tasks.Shell>
  </builders>
  <publishers />
  <buildWrappers />
</project>" > app01_job.xml
```

```bash
jenkins-cli create-job app01 < app01_job.xml
```

```bash
jenkins-cli build app01
```

```bash
jenkins-cli get-job app01
```

```xml
<?xml version="1.1" encoding="UTF-8"?>
<project>
  <actions />
  <description>app01</description>
  <keepDependencies>false</keepDependencies>
  <properties />
  <scm class="hudson.plugins.git.GitSCM">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <name>app01</name>
        <url>http://gogs.local:3000/administrator/apps.git</url>
        <credentialsId>k8s</credentialsId>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
    <branches>
      <hudson.plugins.git.BranchSpec>
        <name>*/master</name>
      </hudson.plugins.git.BranchSpec>
    </branches>
    <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    <submoduleCfg class="empty-list" />
    <extensions />
  </scm>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers>
    <hudson.triggers.SCMTrigger>
      <spec>H/5 * * * *</spec>
      <ignorePostCommitHooks>false</ignorePostCommitHooks>
    </hudson.triggers.SCMTrigger>
  </triggers>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.tasks.Shell>
      <command>echo &quot;app01&quot;
curl -LO &quot;https://storage.googleapis.com/kubernetes-release/release/v1.22.2/bin/linux/amd64/kubectl&quot;
chmod +x ./kubectl
./kubectl get no
./kubectl apply -f apps/app01/app01_list.yaml</command>
      <configuredLocalRules />
    </hudson.tasks.Shell>
  </builders>
  <publishers />
  <buildWrappers />
</project>
```

### Create pipeline jobs for app02 and app03

```bash
echo "<?xml version='1.1' encoding='UTF-8'?>
<flow-definition>
  <actions/>
  <description>app02</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class='org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition'>
    <script>timestamps {
node () {
	stage (&apos;app02 - Checkout&apos;) {
 	 checkout([\$class: &apos;GitSCM&apos;, branches: [[name: &apos;*/master&apos;]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: &apos;k8s&apos;, url: &apos;http://gogs.local:3000/administrator/apps.git&apos;]]])
	}
	stage (&apos;app02 - Build&apos;) {
sh &apos;&apos;&apos;
echo &quot;app02&quot;
curl -LO &quot;https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl&quot;
chmod +x ./kubectl
./kubectl get no
./kubectl apply -f apps/app02/app02_list.yaml
  &apos;&apos;&apos;
}
}
}</script>
    <sandbox>true</sandbox>
  </definition>
  <disabled>false</disabled>
</flow-definition>" > app02_pipeline_script.xml
```

```bash
jenkins-cli create-job app02 < app02_pipeline_script.xml
```

```bash
jenkins-cli build app02
```

```
jenkins-cli get-job app02
```

```xml
<?xml version="1.1" encoding="UTF-8"?>
<flow-definition>
  <actions />
  <description>app02</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition">
    <script>timestamps {
node () {
stage (&apos;app02 - Checkout&apos;) {
  checkout([$class: &apos;GitSCM&apos;, branches: [[name: &apos;*/master&apos;]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: &apos;k8s&apos;, url: &apos;http://gogs.local:3000/administrator/apps.git&apos;]]])
}
stage (&apos;app02 - Build&apos;) {
sh &apos;&apos;&apos;
echo &quot;app02&quot;
curl -LO &quot;https://storage.googleapis.com/kubernetes-release/release/v1.22.2/bin/linux/amd64/kubectl&quot;
chmod +x ./kubectl
./kubectl get no
./kubectl apply -f apps/app02/app02_list.yaml
  &apos;&apos;&apos;
}
}
}</script>
    <sandbox>true</sandbox>
  </definition>
  <disabled>false</disabled>
</flow-definition>
```

```bash
echo "<?xml version='1.1' encoding='UTF-8'?>
<flow-definition>
  <actions />
  <description>app03</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class='org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition'>
    <scm class='hudson.plugins.git.GitSCM'>
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>http://gogs.local:3000/administrator/apps.git</url>
          <credentialsId>k8s</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/master</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class='empty-list' />
      <extensions />
    </scm>
    <scriptPath>apps/app03/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <disabled>false</disabled>
</flow-definition>" > app03_pipeline_jenkinsfile.xml
```

```bash
jenkins-cli create-job app03 < app03_pipeline_jenkinsfile.xml
```

```bash
jenkins-cli build app03
```

```bash
jenkins-cli get-job app03
```

```xml
<?xml version="1.1" encoding="UTF-8"?>
<flow-definition>
  <actions />
  <description>app03</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>http://gogs.local:3000/administrator/apps.git</url>
          <credentialsId>k8s</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/master</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list" />
      <extensions />
    </scm>
    <scriptPath>apps/app03/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <disabled>false</disabled>
</flow-definition>
```

### List jobs

```bash
jenkins-cli list-jobs
```

```text
app01
app02
app03
```

Sources:
<https://microk8s.io/>

<https://gogs.io/>

<https://www.jenkins.io/>

<https://www.jenkins.io/doc/book/managing/cli/>
