#!/bin/bash

# Script Name: deployVaultHelm.sh
# Author: Juan Monge
# Description: This script performs Helm and Kubernetes operations to uninstall and delete the Vault and Vault Agent Injector.

# Uninstall the Vault Helm release
echo "Uninstalling Vault Helm release..."
helm uninstall vault

# Wait for a few seconds to make sure the release is deleted
echo "Waiting for release to be deleted..."
sleep 5

# Optionally, you can also delete the Helm repository if it is not going to be used further
echo "Removing HashiCorp Helm repository..."
helm repo remove hashicorp

# Update the Helm repository listings to remove hashicorp from the list
echo "Updating Helm repositories..."
helm repo update

# Display all the pods in the default namespace to verify that the pods have been deleted
echo "Displaying all pods in the default namespace..."
kubectl get pods

# Script ends here
echo "Script execution complete."
