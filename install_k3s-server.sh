#!/bin/bash

# Download and install k3s
INSTALL_K3S_EXEC="--disable servicelb"
curl -sfL https://get.k3s.io > setup_script 
chmod +x setup_script
./setup_script --cluster-cidr "172.30.0.0/16" \
		  			--service-cidr "172.31.0.0/16" \
		  			--cluster-dns  "172.31.0.10" \
		  			--cluster-domain "nathan.home"

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
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
k3s kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml
k3s kubectl create -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml
k3s kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token' > token.txt
