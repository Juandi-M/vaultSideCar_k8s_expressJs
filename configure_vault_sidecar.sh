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
kubectl create serviceaccount vault-auth -n $NAMESPACE || echo "Service account 'vault-auth' already exists. Continuing..."

# Step 3: Configure Kubernetes Authentication in Vault

TOKEN_REVIEWER_JWT=$(kubectl get secret $(kubectl get serviceaccount vault-auth -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode)
vault write auth/kubernetes/config \
    token_reviewer_jwt="$TOKEN_REVIEWER_JWT" \
    kubernetes_host="$KUBERNETES_HOST" \
    kubernetes_ca_cert=@$HOME/ca.crt

# Step 3: Create a Vault Policy
POLICY_NAME="juan-web-poc-policy"  
echo "path \"devops/kv/vault-templating-poc/*\" { capabilities = [\"read\"] }" > $POLICY_NAME.hcl
vault policy write $POLICY_NAME $POLICY_NAME.hcl

# Step 4: Create a Role in Vault
ROLE_NAME="juan-web-poc-policy"
vault write auth/kubernetes/role/$ROLE_NAME \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=$NAMESPACE \
    policies=policies=juan-web-poc-policy\
    ttl=24h

#  Step 5 Conclusion:
echo "--------------------------------------------------"
echo "Configuration and Integration Completed Successfully!"
echo "--------------------------------------------------"
echo "Here's what has been configured and integrated:"
echo "1. Kubernetes API Server URL and CA certificate have been obtained."
echo "2. A Kubernetes service account named 'vault-auth' has been created."
echo "3. Kubernetes authentication has been configured in Vault."
echo "4. A Vault policy named '$POLICY_NAME' has been created."
echo "5. A Vault role named '$ROLE_NAME' has been created and bound to the service account."
echo ""
echo "Next Steps:"
echo "1. Verify the integration by checking the logs from the Vault sidecar container in your Kubernetes application."
echo "2. Run no the helm installation of the injector: deploy-vault-helm.sh."
echo "--------------------------------------------------"
