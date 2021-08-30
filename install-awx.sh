#!/bin/bash
#install-awx.sh

sudo apt -y update && sudo apt -y upgrade
sudo apt install docker.io -y
sudo snap install microk8s --classic
usermod -aG microk8s $USER
echo "alias kubectl='microk8s.kubectl'" >> /home/$USER/.bash_aliases
kubectl get nodes
kubectl get pods
kubectl get pods -A
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/0.12.0/deploy/awx-operator.yaml
kubectl get pods
echo "
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
  ingress_type: none
  hostname: awx-demo.example.com" > awx-demo.yml
kubectl apply -f awx-demo.yml
kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"
kubectl get svc -l "app.kubernetes.io/managed-by=awx-operator"
kubectl get secrets
kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode
kubectl expose deployment awx-demo --type=LoadBalancer --port=8080
kubectl port-forward svc/awx-demo-service --address 0.0.0.0 30886:80
