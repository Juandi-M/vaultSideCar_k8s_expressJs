#!/bin/bash

VAULT_VALUES_FILE="vault-values.yaml"
VAULT_HELM_RELEASE="vault"
NAMESPACE="default"

# Function to add and update the HashiCorp Helm Repository
add_update_helm_repo() {
  echo "Adding and updating HashiCorp Helm Repository..."
  helm repo list | grep "hashicorp" &> /dev/null
  if [ $? -ne 0 ]; then
    helm repo add hashicorp https://helm.releases.hashicorp.com
  fi
  helm repo update
}

# Function to check Vault Helm installation status
check_installation_status() {
  echo "Checking Vault Helm installation status..."
  helm status $VAULT_HELM_RELEASE -n $NAMESPACE &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Error: Vault Helm installation not found or not healthy."
    return 1
  fi
  return 0
}

# Function to deploy Vault Helm
deploy_vault_helm() {
  echo "Deploying Vault Helm..."
  helm install $VAULT_HELM_RELEASE hashicorp/vault -f $VAULT_VALUES_FILE -n $NAMESPACE
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install Vault Helm release."
    exit 1
  fi
}

# Function to redeploy Vault Helm
redeploy_vault_helm() {
  read -p "Do you want to redeploy Vault Helm? [y/N]: " decision
  if [[ "$decision" == "y" || "$decision" == "Y" ]]; then
    echo "Redeploying Vault Helm..."
    helm uninstall $VAULT_HELM_RELEASE -n $NAMESPACE
    deploy_vault_helm
    echo "Redeployment completed."
  else
    echo "Redeployment skipped."
  fi
}

# Main script execution
echo "Starting Vault Helm Deployment Verification..."
add_update_helm_repo

if check_installation_status; then
  echo "Vault Helm installation is healthy."
else
  echo "Issues detected with Vault Helm installation."
  redeploy_vault_helm
fi

# Verification Step
echo "Verifying Vault Sidecar Integration..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=web-app -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
  echo "Error: Unable to find the appropriate pod for verification."
  exit 1
fi

echo "Retrieving logs from the Vault sidecar container..."
kubectl logs $POD_NAME -c vault-agent -n $NAMESPACE

echo "Verification completed. Check the logs above for details."
echo "You've successfully integrated the Vault sidecar injector into your Kubernetes application."

# Conclusion
echo "Your application can now securely access secrets stored in HashiCorp Vault."

# Conclusion Step
echo "--------------------------------------------------"
echo "Vault Helm Deployment Completed Successfully!"
echo "--------------------------------------------------"
echo "Here's what has been done:"
echo "1. HashiCorp Helm repository has been added and updated."
echo "2. Checked the status of the existing Vault Helm installation."
echo "3. Deployed or redeployed the Vault Helm release based on the provided values file."
echo ""
echo "Next Steps:"
echo "1. Verify the Vault Helm deployment by running 'helm status $VAULT_HELM_RELEASE' to ensure the Vault server injector is deployed correctly."
echo "2. Check if the Vault injector has its own pod running by using 'kubectl get pods -n <namespace>' and looking for the injector pod."
echo "3. Confirm that the web-app pod has Vault initialization inside by inspecting the logs or metadata of the web-app pod using 'kubectl logs <web-app-pod-name> -n <namespace>' or 'kubectl describe pod <web-app-pod-name> -n <namespace>'."