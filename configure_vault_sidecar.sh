#!/bin/bash

# Script Name: configure_vault_sidecar.sh
# Author: Juan Monge
# Description: Configuring Kubernetes Authentication with Vault and integrating Vault Sidecar Injector

# Step 1: Obtain Kubernetes Information
KUBERNETES_API_SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
export KUBERNETES_HOST=$KUBERNETES_API_SERVER_URL
kubectl get configmap -n kube-system extension-apiserver-authentication -o=jsonpath='{.data.client-ca-file}' > ~/ca.crt

# Step 2: Kubernetes Service Account
NAMESPACE="default" # Replace with the desired namespace
kubectl create serviceaccount vault-auth -n $NAMESPACE

# Step 3: Configure Kubernetes Authentication in Vault
export VAULT_ADDR='YOUR_VAULT_URL' # Replace with your Vault URL
TOKEN_REVIEWER_JWT=$(kubectl get secret $(kubectl get serviceaccount vault-auth -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode)
vault write auth/kubernetes/config \
    token_reviewer_jwt="$TOKEN_REVIEWER_JWT" \
    kubernetes_host="$KUBERNETES_HOST" \
    kubernetes_ca_cert=@$HOME/ca.crt

# Step 3: Create a Vault Policy
POLICY_NAME="myapp-policy"
echo "path \"devops/kv/vault-templating-poc/*\" { capabilities = [\"read\"] }" > $POLICY_NAME.hcl
vault policy write $POLICY_NAME $POLICY_NAME.hcl

# Step 4: Create a Role in Vault
ROLE_NAME="web-app-render"
vault write auth/kubernetes/role/$ROLE_NAME \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=$NAMESPACE \
    policies=web-app-render-policy \
    ttl=24h

# Step 5: Verify the Integration
# Find the appropriate pod name containing the Vault sidecar container
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=web-app -o jsonpath='{.items[0].metadata.name}')

# Check if the pod name was found
if [ -z "$POD_NAME" ]; then
  echo "Error: Unable to find the appropriate pod for verification."
  exit 1
fi

# Retrieve the logs from the Vault sidecar container
kubectl logs $POD_NAME -c vault-agent -n $NAMESPACE

echo "Verification completed. Check the logs above for details."

echo "You've successfully integrated the Vault sidecar injector into your Kubernetes application."

# Conclusion: Your application can now securely access secrets stored in HashiCorp Vault
