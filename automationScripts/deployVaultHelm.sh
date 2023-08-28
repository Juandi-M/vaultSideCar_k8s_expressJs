#!/bin/bash

# Script Name: deployVaultHelm.sh
# Author: Juan Monge
# Description: Configuring Kubernetes Authentication with Vault and integrating Vault Sidecar Injector

# Add the HashiCorp Helm repository
echo "Adding HashiCorp Helm repository..."
helm repo add hashicorp https://helm.releases.hashicorp.com

# Update all the repositories
echo "Updating Helm repositories..."
helm repo update

# Install Vault with specified settings
echo "Installing Vault..."
EXTERNAL_VAULT_ADDR="hcvault-sandbox.llm-aws.com"  # Set your actual External Vault Address
helm install vault hashicorp/vault \
  --set "injector.externalVaultAddr=https://$EXTERNAL_VAULT_ADDR:8200" \
  # --set "tlsDisable=true" \
  --set='server.enabled=false'

# Wait for a few seconds to make sure the injector pod is getting deployed
echo "Waiting for injector pod to be deployed..."
sleep 20

# Display all the pods in the default namespace
echo "Displaying all pods in the default namespace..."
kubectl get pods

# Script ends here
echo "Script execution complete."
