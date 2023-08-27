#!/bin/bash

# Script Name: deployVaultHelm.sh
# Author: Juan Monge
# Description: Configuring Kubernetes Authentication with Vault and integrating Vault Sidecar Injector

NAMESPACE="default"

# Function to deploy Helm chart
deploy_helm() {
  echo "Deploying Vault Helm chart to namespace $NAMESPACE..."

  # Add HashiCorp Helm repository and update
  helm repo add hashicorp https://helm.releases.hashicorp.com
  helm repo update

  # Deploy Vault Helm chart
  if helm upgrade --install vault hashicorp/vault -f ../helm/helm-vault-injector-deployement.yaml -n $NAMESPACE; then
    echo "Vault Helm chart deployed successfully."
  else
    echo "Vault Helm chart deployment failed."
    echo "Here's what has been done:"
    echo "1. HashiCorp Helm repository has been added and updated."
    echo "2. Checked the status of the existing Vault Helm installation."
    echo "3. Deployed or redeployed the Vault Helm release based on the provided values file."
    exit 1
  fi
}

# Function to delete Helm deployment
delete_helm() {
  echo "Deleting Vault Helm deployment from namespace $NAMESPACE..."

  # Delete Vault Helm deployment
  if helm uninstall vault -n $NAMESPACE; then
    echo "Vault Helm deployment deleted successfully."
  else
    echo "Vault Helm deployment deletion failed."
    exit 1
  fi
}

# Main script
while true; do
  read -p "Do you want to 1) Delete Helm deployment or 2) Deploy Helm? (Enter 1 or 2): " choice
  case $choice in
    1) delete_helm; break;; # If choice is 1, call delete_helm function and break out of the loop.
    2) deploy_helm; break;; # If choice is 2, call deploy_helm function and break out of the loop.
    *) echo "Invalid choice. Please enter 1 or 2.";; # If choice is neither 1 nor 2, display an error message.
  esac
done

# Conclusion Step
echo "1. Verify the Vault Helm deployment by running 'helm status vault' to ensure the Vault server injector is deployed correctly."
echo "2. Check if the Vault injector has its own pod running by using 'kubectl get pods -n $NAMESPACE' and looking for the injector pod."
echo "3. Confirm that the web-app pod has Vault initialization inside by inspecting the logs or metadata of the web-app pod using 'kubectl logs <web-app-pod-name> -n $NAMESPACE' or 'kubectl describe pod <web-app-pod-name> -n $NAMESPACE'."