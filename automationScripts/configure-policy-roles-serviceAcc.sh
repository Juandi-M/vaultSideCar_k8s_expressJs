#!/bin/bash

# Script Name: configure-vault-auth-and-roles.sh
# Author: Juan Monge
# Description: This script configures Kubernetes authentication on a remote Vault server, and sets up secret store, policy, and roles.

# Your Vault Server Address
VAULT_ADDR="https://hcvault-sandbox.llm-aws.com:8200"
export VAULT_ADDR=$VAULT_ADDR

# Check if Kubernetes authentication is already enabled
if vault auth list | grep -q 'kubernetes/'; then
  echo "Kubernetes auth is already enabled."
else
  echo "Enabling Kubernetes authentication..."
  vault auth enable kubernetes
fi

# Fetch Kubernetes API Server Address and CA Certificate
KUBE_API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
KUBE_CA_CERT=$(kubectl get secret -o jsonpath="{.data['ca\.crt']}" $(kubectl get sa default -o jsonpath="{.secrets[0].name}") | base64 --decode)

# Configure Kubernetes authentication
echo "Configuring Kubernetes authentication..."
vault write auth/kubernetes/config \
      kubernetes_host="$KUBE_API_SERVER" \
      kubernetes_ca_cert="$KUBE_CA_CERT"

# Create a Vault policy to specify permissions for the existing secret store
echo "Creating Vault policy named juan-vault-web-poc..."
vault policy write juan-vault-web-poc - <<EOF
path "devops/kv/vault-templating-poc/*" {
  capabilities = ["read"]
}
EOF

# Create Kubernetes authentication role for the specific namespace and service account
echo "Creating Kubernetes authentication role named juan-vault-web-poc..."
vault write auth/kubernetes/role/juan-vault-web-poc \
      bound_service_account_names=juan-vault-web-poc \
      bound_service_account_namespaces=default \
      policies=juan-vault-web-poc \
      ttl=24h

# Create ServiceAccount  
echo "Creating ServiceAccount named juan-vault-web-poc..."

if ! kubectl get serviceaccount juan-vault-web-poc > /dev/null 2>&1; then
  kubectl create sa juan-vault-web-poc
else
  echo "Service account juan-vault-web-poc already exists, skipping creation" 
fi

# Script ends here
echo "Script execution complete."