## Install Multipass

```bash
sudo snap install multipass --classic
```

# MicroK8s

MicroK8s is the smallest, fastest, fully-conformant Kubernetes that tracks upstream releases and makes clustering trivial. MicroK8s is great for offline development, prototyping, and testing.

## Create a MicroK8s templates

### Control

```bash
echo '#cloud-config
runcmd:
  - apt update --fix-missing
  - snap refresh
  - snap install microk8s --classic
  - microk8s status --wait-ready
  - microk8s add-node --token-ttl 126144000 --token 868f88ee477f893de65c99d906e767dcaf59ce10fe30795ef9b2d11af4faefa
  - microk8s enable dns' > cloud-config-microk8s-control.yaml
```

## Create a MicroK8s instances

### Control

```bash
multipass launch focal -n microk8s -c 2 -m 4G -d 10G --cloud-init cloud-config-microk8s-control.yaml
```

### Add an IP alias of the microk8s instance to microk8s.multipass

```bash
multipass info microk8s | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     microk8s.multipass/' | tee -a /etc/hosts
```

## Export the current MicroK8s configuration for use with Kubectl

### Create the folder to store the configuration of the Kubernetes cluster in the instance

```bash
mkdir -p $HOME/.kube/configs
chown -R $USER: $HOME/.kube/
```

### Export the MicroK8s configuration in the instance to the created folder

```bash
multipass exec microk8s -- microk8s config > $HOME/.kube/configs/config-microk8s
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
microk8s   Ready    <none>   33m   v1.22.4-3+adc4115d990346
```

### URL for microk8s.multipass

<http://microk8s.multipass>

# Deploy the Metrics Server

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm install metrics-server metrics-server/metrics-server --set 'args={--kubelet-insecure-tls}' --namespace kube-system --create-namespace
```

```bash
kubectl get deployment metrics-server -n kube-system
```

# Deploy the Kube-State-Metrics

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-state-metrics prometheus-community/kube-state-metrics --namespace monitoring --create-namespace
```

```bash
kubectl get deployment kube-state-metrics -n monitoring
```

## Create a ELK templates

### Elasticsearch and Kibana

```bash
echo '#cloud-config
write_files:
  - path: /etc/apt/sources.list.d/elastic-7.x.list
    owner: root:root
    permissions: 0644
    content: |
      deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main
    append: true
  - path: /etc/elasticsearch/elasticsearch.yml.template
    owner: root:root
    permissions: 0660
    content: |
      transport.host: localhost
      transport.tcp.port: 9300
      network.host: 0.0.0.0
      http.port: 9200
      cluster.name: kibana
      path.data: /var/lib/elasticsearch
      path.logs: /var/log/elasticsearch
      action.auto_create_index: true
    append: true
  - path: /etc/kibana/kibana.yml.template
    owner: root:root
    permissions: 0660
    content: |
      server.host: 0.0.0.0
      server.name: kibana
      elasticsearch.hosts: ["http://localhost:9200"]
    append: true
runcmd:
  - echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment
  - source /etc/environment
  - wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
  - apt update --fix-missing
  - apt -y remove snapd --purge
  - apt -y install apt-transport-https
  - apt -y install elasticsearch-oss
  - cp -raf /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.backup
  - cp -raf /etc/elasticsearch/elasticsearch.yml.template /etc/elasticsearch/elasticsearch.yml
  - chown -R root:elasticsearch /etc/elasticsearch
  - mkdir -p /var/run/elasticsearch
  - touch /var/run/elasticsearch/elasticsearch.pid
  - chown -R elasticsearch:elasticsearch /var/run/elasticsearch
  - chown -R elasticsearch:elasticsearch /usr/share/elasticsearch
  - systemctl daemon-reload
  - systemctl enable elasticsearch
  - systemctl start elasticsearch
  - update-rc.d elasticsearch defaults 95 10
  - apt -y install kibana-oss
  - cp -raf /etc/kibana/kibana.yml /etc/kibana/kibana.yml.backup
  - cp -raf /etc/kibana/kibana.yml.template /etc/kibana/kibana.yml
  - chown -R root:kibana /etc/kibana
  - mkdir -p /var/run/kibana
  - touch /var/run/kibana/kibana.pid
  - chown -R kibana:kibana /var/run/kibana
  - chown -R kibana:kibana /usr/share/kibana
  - systemctl daemon-reload
  - systemctl enable kibana
  - systemctl start kibana
  - update-rc.d kibana defaults 95 10' > cloud-config-kibana.yaml
```

## Create ELK instances

### Kibana

```bash
multipass launch focal -n kibana -c 2 -m 3G -d 10G --cloud-init cloud-config-kibana.yaml
```

### Add an IP alias of the kibana instance to kibana.multipass

```bash
multipass info kibana | grep IPv4 | cut -f 2 -d ":" | tr -d [:blank:] | sed 's/$/     kibana.multipass/' | tee -a /etc/hosts
```

## Run Filebeat on Kubernetes

To download the manifest file, run:

```bash
curl -L -O https://raw.githubusercontent.com/elastic/beats/7.10/deploy/kubernetes/filebeat-kubernetes.yaml
```

### Copy template for OSS

```bash
cp filebeat-kubernetes.yaml filebeat-kubernetes_oss.yaml
```

#### Change IP

```bash
sed -i "s/:\elasticsearch/:\kibana.multipass/" filebeat-kubernetes_oss.yaml
```

#### Change image to OSS

```bash
sed -i "s/filebeat\:/filebeat-oss\:/" filebeat-kubernetes_oss.yaml
```

Or

```bash
echo '---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: kube-system
  labels:
    k8s-app: filebeat
data:
  filebeat.yml: |-
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/*.log
      processors:
        - add_kubernetes_metadata:
            host: ${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
    processors:
      - add_cloud_metadata:
      - add_host_metadata:
    cloud.id: ${ELASTIC_CLOUD_ID}
    cloud.auth: ${ELASTIC_CLOUD_AUTH}
    output.elasticsearch:
      hosts: ['${ELASTICSEARCH_HOST:kibana.multipass}:${ELASTICSEARCH_PORT:9200}']
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: kube-system
  labels:
    k8s-app: filebeat
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      serviceAccountName: filebeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat-oss:7.10.2
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        env:
        - name: ELASTICSEARCH_HOST
          value: "kibana.multipass"
        - name: ELASTICSEARCH_PORT
          value: "9200"
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /etc/filebeat.yml
          readOnly: true
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: varlog
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: config
        configMap:
          defaultMode: 0640
          name: filebeat-config
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: varlog
        hostPath:
          path: /var/log
      - name: data
        hostPath:
          path: /var/lib/filebeat-data
          type: DirectoryOrCreate
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
- kind: ServiceAccount
  name: filebeat
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: filebeat
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: kube-system
roleRef:
  kind: Role
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: filebeat-kubeadm-config
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: kube-system
roleRef:
  kind: Role
  name: filebeat-kubeadm-config
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
  labels:
    k8s-app: filebeat
rules:
  resources:
  - namespaces
  - pods
  - nodes
  verbs:
  - get
  - watch
  - list
- apiGroups: ["apps"]
  resources:
    - replicasets
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: filebeat
  namespace: kube-system
  labels:
    k8s-app: filebeat
rules:
  - apiGroups:
      - coordination.k8s.io
    resources:
      - leases
    verbs: ["get", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: filebeat-kubeadm-config
  namespace: kube-system
  labels:
    k8s-app: filebeat
rules:
  - apiGroups: [""]
    resources:
      - configmaps
    resourceNames:
      - kubeadm-config
    verbs: ["get"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: kube-system
  labels:
    k8s-app: filebeat
---' > filebeat-kubernetes_oss.yaml
```

### Deploy

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

```bash
kubectl get no
```

```txt
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   33m   v1.22.4-3+adc4115d990346
```

To deploy Filebeat to Kubernetes, run:

```bash
kubectl create -f filebeat-kubernetes_oss.yaml
```

To check the status, run:

```bash
kubectl get ds/filebeat -n kube-system
```

```text
NAME       DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
filebeat   1         1         1       1            1           <none>          1m
```

## Run Metricbeat on Kubernetes

To download the manifest file, run:

```bash
curl -L -O https://raw.githubusercontent.com/elastic/beats/7.10/deploy/kubernetes/metricbeat-kubernetes.yaml
```

### Copy template for OSS

```bash
cp metricbeat-kubernetes.yaml metricbeat-kubernetes_oss.yaml
```

#### Change IP

```bash
sed -i "s/:\elasticsearch/:\kibana.multipass/" metricbeat-kubernetes_oss.yaml
```

#### Change image to OSS

```bash
sed -i "s/metricbeat\:/metricbeat-oss\:/" metricbeat-kubernetes_oss.yaml
```

Or

```bash
echo '---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metricbeat-daemonset-config
  namespace: kube-system
  labels:
    k8s-app: metricbeat
data:
  metricbeat.yml: |-
    metricbeat.config.modules:
      path: ${path.config}/modules.d/*.yml
      reload.enabled: false
    metricbeat.autodiscover:
      providers:
        - type: kubernetes
          scope: cluster
          node: ${NODE_NAME}
          unique: true
          templates:
            - config:
                - module: kubernetes
                  hosts: ["kube-state-metrics:8080"]
                  period: 10s
                  add_metadata: true
                  metricsets:
                    - state_node
                    - state_deployment
                    - state_daemonset
                    - state_replicaset
                    - state_pod
                    - state_container
                    - state_job
                    - state_cronjob
                    - state_resourcequota
                    - state_statefulset
                    - state_service
                - module: kubernetes
                  metricsets:
                    - apiserver
                  hosts: ["https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"]
                  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
                  ssl.certificate_authorities:
                    - /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                  period: 30s
    processors:
      - add_cloud_metadata:
    cloud.id: ${ELASTIC_CLOUD_ID}
    cloud.auth: ${ELASTIC_CLOUD_AUTH}
    output.elasticsearch:
      hosts: ['${ELASTICSEARCH_HOST:kibana.multipass}:${ELASTICSEARCH_PORT:9200}']
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metricbeat-daemonset-modules
  namespace: kube-system
  labels:
    k8s-app: metricbeat
data:
  system.yml: |-
    - module: system
      period: 10s
      metricsets:
        - cpu
        - load
        - memory
        - network
        - process
        - process_summary
      processes: ['.*']
      process.include_top_n:
    - module: system
      period: 1m
      metricsets:
        - filesystem
        - fsstat
      processors:
      - drop_event.when.regexp:
          system.filesystem.mount_point: '^/(sys|cgroup|proc|dev|etc|host|lib|snap)($|/)'
  kubernetes.yml: |-
    - module: kubernetes
      metricsets:
        - node
        - system
        - pod
        - container
        - volume
      period: 10s
      host: ${NODE_NAME}
      hosts: ["https://${NODE_NAME}:10250"]
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      ssl.verification_mode: "none"
    - module: kubernetes
      metricsets:
        - proxy
      period: 10s
      host: ${NODE_NAME}
      hosts: ["localhost:10249"]
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: metricbeat
  namespace: kube-system
  labels:
    k8s-app: metricbeat
spec:
  selector:
    matchLabels:
      k8s-app: metricbeat
  template:
    metadata:
      labels:
        k8s-app: metricbeat
    spec:
      serviceAccountName: metricbeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
        - name: metricbeat
          image: docker.elastic.co/beats/metricbeat-oss:7.10.2
          args: ["-c", "/etc/metricbeat.yml", "-e", "-system.hostfs=/hostfs"]
          env:
            - name: ELASTICSEARCH_HOST
              value: "kibana.multipass"
            - name: ELASTICSEARCH_PORT
              value: "9200"
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          securityContext:
            runAsUser: 0
          resources:
            limits:
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 100Mi
          volumeMounts:
            - name: config
              mountPath: /etc/metricbeat.yml
              readOnly: true
              subPath: metricbeat.yml
            - name: data
              mountPath: /usr/share/metricbeat/data
            - name: modules
              mountPath: /usr/share/metricbeat/modules.d
              readOnly: true
            - name: proc
              mountPath: /hostfs/proc
              readOnly: true
            - name: cgroup
              mountPath: /hostfs/sys/fs/cgroup
              readOnly: true
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: cgroup
          hostPath:
            path: /sys/fs/cgroup
        - name: config
          configMap:
            defaultMode: 0640
            name: metricbeat-daemonset-config
        - name: modules
          configMap:
            defaultMode: 0640
            name: metricbeat-daemonset-modules
        - name: data
          hostPath:
            path: /var/lib/metricbeat-data
            type: DirectoryOrCreate
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metricbeat
subjects:
  - kind: ServiceAccount
    name: metricbeat
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: metricbeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: metricbeat
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: metricbeat
    namespace: kube-system
roleRef:
  kind: Role
  name: metricbeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: metricbeat-kubeadm-config
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: metricbeat
    namespace: kube-system
roleRef:
  kind: Role
  name: metricbeat-kubeadm-config
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: metricbeat
  labels:
    k8s-app: metricbeat
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - namespaces
      - events
      - pods
      - services
    verbs: ["get", "list", "watch"]
  - apiGroups: ["extensions"]
    resources:
      - replicasets
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources:
      - statefulsets
      - deployments
      - replicasets
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources:
      - jobs
    verbs: ["get", "list", "watch"]
  - apiGroups:
      - ""
    resources:
      - nodes/stats
    verbs:
      - get
  - nonResourceURLs:
      - "/metrics"
    verbs:
      - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: metricbeat
  namespace: kube-system
  labels:
    k8s-app: metricbeat
rules:
  - apiGroups:
      - coordination.k8s.io
    resources:
      - leases
    verbs: ["get", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: metricbeat-kubeadm-config
  namespace: kube-system
  labels:
    k8s-app: metricbeat
rules:
  - apiGroups: [""]
    resources:
      - configmaps
    resourceNames:
      - kubeadm-config
    verbs: ["get"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metricbeat
  namespace: kube-system
  labels:
    k8s-app: metricbeat
---' > metricbeat-kubernetes_oss.yaml
```

### Deploy

```bash
export KUBECONFIG=$HOME/.kube/configs/config-microk8s
```

```bash
kubectl get no
```

```txt
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   33m   v1.22.4-3+adc4115d990346
```

Metricbeat gets some metrics from kube-state-metrics. If kube-state-metrics is not already running, deploy it.

To deploy Metricbeat to Kubernetes, run:

```bash
kubectl create -f metricbeat-kubernetes_oss.yaml
```

To check the status, run:

```bash
kubectl get ds/metricbeat -n kube-system
```

```text
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
metricbeat   1         1         1       1            1           <none>          1m
```

# Instance install

## Create Multipass instance

### Teste instance

```bash
multipass launch focal -n teste -c 2 -m 1G -d 3G
```

### connect to teste instance

```bash
multipass shell teste
```

```bash
sudo su root
```

## Filebeat

### Download and install Filebeat

```bash
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-oss-7.10.2-amd64.deb
dpkg -i filebeat-oss-7.10.2-amd64.deb
```

### Edit the configuration

```bash
cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.backup
cat /etc/filebeat/filebeat.yml.backup | egrep -v "^$|#" > /etc/filebeat/filebeat.yml.template
cat /etc/filebeat/filebeat.yml.backup | egrep -v "^$|#" > /etc/filebeat/filebeat.yml
nano -c /etc/filebeat/filebeat.yml
```

Or

```bash
echo 'filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
- type: filestream
  enabled: true
  paths:
    - /var/log/*.log
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: true
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
  host: "kibana.multipass:5601"
output.elasticsearch:
  hosts: ["kibana.multipass:9200"]
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
setup.ilm.overwrite: true
output.elasticsearch.index: "teste_filebeat-%{[agent.version]}-%{+yyyy.MM.dd}"
setup.template.name: "teste_filebeat"
setup.template.pattern: "teste_filebeat-*"
setup.dashboards.index: "teste_filebeat-*"' > /etc/filebeat/filebeat.yml
```

### Disable and configure the kibana module

```bash
filebeat modules disable kibana
filebeat modules disable system
filebeat modules enable kibana
filebeat modules enable system
```

### Start Filebeat

```bash
service filebeat stop
filebeat setup
service filebeat start
```

```bash
systemctl enable filebeat
systemctl status filebeat -l
```

## Metricbeat

### Download and install Metricbeat

```bash
curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-oss-7.10.2-amd64.deb
dpkg -i metricbeat-oss-7.10.2-amd64.deb
```

```bash
cp /etc/metricbeat/metricbeat.yml /etc/metricbeat/metricbeat.yml.backup
cat /etc/metricbeat/metricbeat.yml.backup | egrep -v "^$|#" > /etc/metricbeat/metricbeat.yml.template
cat /etc/metricbeat/metricbeat.yml.backup | egrep -v "^$|#" > /etc/metricbeat/metricbeat.yml
nano -c /etc/metricbeat/metricbeat.yml
```

Or

```bash
echo 'metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression
setup.kibana:
  host: "kibana.multipass:5601"
output.elasticsearch:
  hosts: ["kibana.multipass:9200"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
setup.ilm.overwrite: true
output.elasticsearch.index: "teste_metricbeat-%{[agent.version]}-%{+yyyy.MM.dd}"
setup.template.name: "teste_metricbeat"
setup.template.pattern: "teste_metricbeat-*"
setup.dashboards.index: "teste_metricbeat-*"' > /etc/metricbeat/metricbeat.yml
```

```bash
echo '- module: kibana
  period: 10s
  hosts: ["kibana.multipass:5601"]' > /etc/metricbeat/modules.d/kibana.yml.disabled
```

### Disable and configure the kibana module

```bash
metricbeat modules disable kibana
metricbeat modules disable system
metricbeat modules enable kibana
metricbeat modules enable system
```

### Start Metricbeat

```bash
service metricbeat stop
metricbeat setup
service metricbeat start
```

```bash
systemctl enable metricbeat
systemctl status metricbeat -l
```

**Sources:**

<https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html#install-elasticsearch>

<https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html#install-kibana>

<https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html#install-beats>

<https://www.elastic.co/guide/en/beats/filebeat/current/running-on-kubernetes.html>

<https://www.docker.elastic.co/r/beats/filebeat-oss>

<https://www.elastic.co/guide/en/beats/metricbeat/current/running-on-kubernetes.html>

<https://www.docker.elastic.co/r/beats/metricbeat-oss>

<https://github.com/elastic/helm-charts>
