#!/bin/bash

VAULT_VALUES_FILE="vault-values.yaml"
VAULT_HELM_RELEASE="vault"
NAMESPACE="default"

# Function to add and update the HashiCorp Helm Repository
add_update_helm_repo() {
  helm repo list | grep "hashicorp" &> /dev/null
  if [ $? -ne 0 ]; then
    helm repo add hashicorp https://helm.releases.hashicorp.com
  fi
  helm repo update
}

# Function to check Vault Helm installation status
check_installation_status() {
  helm status $VAULT_HELM_RELEASE -n $NAMESPACE &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Error: Vault Helm installation not found or not healthy."
    return 1
  fi
  return 0
}

# Function to check Vault Helm version
check_version() {
  # Logic to check if the installed version is outdated
  # This may vary depending on how you manage versions in your setup
  return 0
}

# Function to deploy Vault Helm
deploy_vault_helm() {
  helm install $VAULT_HELM_RELEASE hashicorp/vault -f $VAULT_VALUES_FILE -n $NAMESPACE
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install Vault Helm release."
    exit 1
  fi
}

# Function to redeploy Vault Helm
redeploy_vault_helm() {
  helm uninstall $VAULT_HELM_RELEASE -n $NAMESPACE
  deploy_vault_helm
}

# Main script execution
echo "Verifying Vault Helm Deployment..."
add_update_helm_repo

if check_installation_status && check_version; then
  echo "Everything is OK!"
else
  echo "Issues detected. Redeploying Vault Helm..."
  redeploy_vault_helm
  echo "Redeployment completed."
fi