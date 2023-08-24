#!/bin/bash

# Change to the directory where the script is located
cd "$(dirname "$0")"

NAMESPACE="default"
VAULT_HELM_RELEASE="vault"
VAULT_HELM_CHART="hashicorp/vault"
VAULT_VALUES_FILE="vault-values.yaml"
VAULT_ADDRESS="https://hcvault-sandbox.llm-aws.com:8200/"

# Function to add and update the HashiCorp Helm Repository
add_update_helm_repo() {
  helm repo list | grep "hashicorp" &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Adding HashiCorp Helm Repository..."
    helm repo add hashicorp https://helm.releases.hashicorp.com
  fi
  echo "Updating Helm Repository..."
  helm repo update
}

# Function to check Vault Agent Injector Service
check_vault_agent_injector() {
  echo "Checking Vault Agent Injector Service..."
  kubectl get svc vault-agent-injector-svc -n $NAMESPACE &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Error: Vault Agent Injector Service not found."
    return 1
  fi
  return 0
}

# Function to check DNS resolution
check_dns_resolution() {
  echo "Checking DNS resolution..."
  kubectl -n kube-system logs -l k8s-app=kube-dns | grep "waiting for Kubernetes API" &> /dev/null
  if [ $? -eq 0 ]; then
    echo "Error: DNS resolution issue detected."
    return 1
  fi
  return 0
}

# Function to check Vault Server Address
check_vault_address() {
  echo "Checking Vault Server Address..."
  # Add logic to verify the Vault address configuration
  # This may vary depending on how you have configured the Vault address in your setup
  return 0
}

# Function to redeploy Vault Helm
redeploy_vault_helm() {
  echo "Redeploying Vault Helm..."
  helm uninstall $VAULT_HELM_RELEASE -n $NAMESPACE
  if [ $? -ne 0 ]; then
    echo "Error: Failed to uninstall Vault Helm release."
    exit 1
  fi
  helm install $VAULT_HELM_RELEASE $VAULT_HELM_CHART -f $VAULT_VALUES_FILE -n $NAMESPACE
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install Vault Helm release."
    exit 1
  fi
}

# Main script execution
echo "Verifying Vault Helm Deployment..."

add_update_helm_repo

if check_vault_agent_injector && check_dns_resolution && check_vault_address; then
  echo "Everything is OK!"
else
  echo "Issues detected. Redeploying Vault Helm..."
  redeploy_vault_helm
  echo "Redeployment completed."
fi