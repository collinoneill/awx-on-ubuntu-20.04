How to install AWX 18+ on Ubuntu 20.04
==================================

Description
-----------
Starting in AWX version 18, AWX is supposed to be installed on Kubernetes. It would be easier to stick with the Docker image, but for some reason they require yet another level of complexity. So here it is!

Prep
----
```bash
sudo apt -y update && sudo apt -y upgrade
```

Install docker
--------------
```bash
sudo apt install docker.io -y
usermod -aG docker $USER
```

Install microk8s
----------------
```bash
sudo snap install microk8s --classic
sudo usermod -aG microk8s $USER
echo "alias kubectl=\"microk8s.kubectl\"" >> /home/$USER/.bash_aliases
kubectl get nodes
kubectl get pods
kubectl get pods -A
```

Install AWX-Operator
--------------------
```bash
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/0.12.0/deploy/awx-operator.yaml
kubectl get pods
```

Create the deployment file
--------------------------
```bash
cat <<EOF | kubectl create -f -
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: 
  name: static-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 2Gi
EOF
```

```bash
echo "
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
  ingress_type: none
  projects_storage_access_mode: ReadWriteOnce
  web_extra_volume_mounts: |
    - name: static-data
      mountPath: /var/lib/awx/public
  extra_volumes: |
    - name: static-data
      persistentVolumeClaim:
        claimName: static-data-pvc" > awx-demo.yml
```

Run the deployment
------------------
```bash
kubectl apply -f awx-demo.yml
kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"
kubectl get svc -l "app.kubernetes.io/managed-by=awx-operator"
```

Wait a few minutes, until all pods are running
----------------------------------------------

Get the Admin user password
---------------------------
```bash
kubectl get secrets
kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode
```

Expose the deployment
---------------------
```bash
kubectl expose deployment awx-demo --type=LoadBalancer --port=8080
```

Enable AWX to be access via the Internet
----------------------------------------
```bash
kubectl port-forward svc/awx-demo-service --address 0.0.0.0 30886:80
```

Test
----
Navigate to http://[yourcomputer.tld]:30886
