#!/bin/bash

# Download and install k3s
INSTALL_K3S_EXEC="--disable servicelb"
curl -sfL https://get.k3s.io > setup_script 
chmod +x setup_script
./setup_script --cluster-cidr "172.30.0.0/16" \
		  			--service-cidr "172.31.0.0/16" \
		  			--cluster-dns  "172.31.0.10" \
		  			--cluster-domain "nathan.home" \
		  			--disable traefik --disable servicelb

# Add helm repos for services
helm repo add metallb https://metallb.github.io/metallb
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Install Services
kubectl create namespace metallb-system
helm install metallb metallb/metallb --namespace metallb-system -f metallb-config.yml

kubectl create namespace longhorn-system
helm install longhorn longhorn/longhorn --namespace longhorn-system

# Install Kubernetes Dashboard
k3s kubectl create -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml

echo "--- KUBERNETES CONFIG ---"
cat /etc/rancher/k3s/k3s.yaml | sed -e "s/127\.0\.0\.1/$(hostname)/" | tee kubeconfig
echo "--- DASHBOARD TOKEN ---"
k3s kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token' | awk '{print $2}'  | tee token.txt

# installing Racher Namespaces
kubectl create namespace cattle-system
kubectl create namespace cert-manager

# instsalling cert-manager
kubectl apply -f cert-manager.crds.yaml
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager

# installing Rancher
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=k3s-rancher.nathan.home
kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher