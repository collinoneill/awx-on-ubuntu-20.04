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
  name: awx
spec:
  service_type: nodeport
  porjects_persistence: true
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
kubectl apply -f awx.yml
kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"
kubectl get svc -l "app.kubernetes.io/managed-by=awx-operator"
```

Wait a few minutes, until all pods are running
----------------------------------------------

Get the Admin user password
---------------------------
```bash
kubectl get secrets
kubectl get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode
```
or a more readable version
```
kubectl get secret awx-admin-password -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

Expose the deployment
---------------------
```bash
kubectl expose deployment awx --type=LoadBalancer --port=8080
```

Enable AWX to be access via the Internet
----------------------------------------
```bash
kubectl port-forward svc/awx-service --address 0.0.0.0 30886:80
```

Test
----
Navigate to http://[yourcomputer.tld]:30886
