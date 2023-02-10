#!/usr/bin/bash

# Download Helm chart
(helm repo add rancher-stable https://releases.rancher.com/server-charts/stable);
(kubectl create namespace cattle-system);

# If you have installed the CRDs manually instead of with the `--set installCRDs=true` option added to your Helm install command, you should upgrade your CRD resources before upgrading the Helm chart:
(kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.1/cert-manager.crds.yaml);

# Add the Jetstack Helm repository
(helm repo add jetstack https://charts.jetstack.io);

# Update your local Helm chart repository cache
(helm repo update);

# Setup kubeconfig file
(export KUBECONFIG=/etc/rancher/k3s/k3s.yaml);

# Install the cert-manager Helm chart
(helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.5.1);

# Verify get pods
(kubectl get pods --namespace cert-manager);

# Install Rancher using Helm
(helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=raspcluster-master.local \
  --set replicas=3 \
  --set bootstrapPassword=pass \
  --set ingress.tls.source=secret);
  
#create cert key and secret
(openssl req -newkey rsa:4096 \
           -x509 \
           -sha256 \
           -days 3650 \
           -nodes \
           -out selfsigned.crt \
           -keyout selfsigned.key);
  
#create secrets
(kubectl -n cattle-system create secret tls tls-rancher-ingress \
  --cert=selfsigned.crt \
  --key=selfsigned.key);

# Status
(kubectl -n cattle-system rollout status deploy/rancher);

# Get status of rancher 
(kubectl -n cattle-system get deploy rancher);
