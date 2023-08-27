#!/bin/bash

# Script Name: configure_vault_sidecar.sh
# Author: Juan Monge
# Description: Configuring Kubernetes Authentication with Vault and integrating Vault Sidecar Injector

export VAULT_ADDR='https://hcvault-sandbox.llm-aws.com:8200/'

# Step 1: Obtain Kubernetes Information
get_kubernetes_api_server_url() {
    kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
}

export KUBERNETES_HOST=$(get_kubernetes_api_server_url)
kubectl get configmap -n kube-system extension-apiserver-authentication -o=jsonpath='{.data.client-ca-file}' > ~/ca.crt

# Step 2: Create a Kubernetes Service Account
NAMESPACE="default" # Replace with the desired namespace
create_service_account() {
    kubectl create serviceaccount vault-auth -n $NAMESPACE || echo "Service account 'vault-auth' already exists. Continuing..."
}

create_service_account

# Step 3: Configure Kubernetes Authentication in Vault
get_token_reviewer_jwt() {
    kubectl get secret $(kubectl get serviceaccount vault-auth -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode
}

configure_kubernetes_authentication() {
    local token_reviewer_jwt="$1"
    local kubernetes_host="$2"
    local ca_cert_file="$3"

    vault write auth/kubernetes/config \
        token_reviewer_jwt="$token_reviewer_jwt" \
        kubernetes_host="$kubernetes_host" \
        kubernetes_ca_cert=@"$ca_cert_file"
}

TOKEN_REVIEWER_JWT=$(get_token_reviewer_jwt)
configure_kubernetes_authentication "$TOKEN_REVIEWER_JWT" "$KUBERNETES_HOST" "$HOME/ca.crt"

# Step 4: Create a Vault Policy
POLICY_NAME="juan-web-poc-policy"
VAULT_POLICY_FILE="/assets/$POLICY_NAME.hcl"

create_vault_policy() {
    local policy_name="$1"
    local vault_policy_file="$2"

    echo "path \"devops/kv/vault-templating-poc/*\" { capabilities = [\"read\"] }" > "$vault_policy_file"
    vault policy write "$policy_name" - <<EOF
$(cat "$vault_policy_file")
EOF
}

create_vault_policy "$POLICY_NAME" "$VAULT_POLICY_FILE"

# Step 5: Create a Role in Vault
ROLE_NAME="juan-web-poc-role"

create_vault_role() {
    local role_name="$1"
    local bound_service_account_names="$2"
    local bound_service_account_namespaces="$3"
    local policies="$4"
    local ttl="$5"

    vault write auth/kubernetes/role/"$role_name" \
        bound_service_account_names="$bound_service_account_names" \
        bound_service_account_namespaces="$bound_service_account_namespaces" \
        policies="$policies" \
        ttl="$ttl"
}

create_vault_role "$ROLE_NAME" "vault-auth" "$NAMESPACE" "$POLICY_NAME" "24h"

# Step 6: Conclusion
if [ $? -eq 0 ]; then
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
    echo "2. Run the Helm installation of the injector: deploy-vault-helm.sh."
    echo "--------------------------------------------------"
fi