#!/bin/bash
set -e

# Check if required commands are installed
command -v vault >/dev/null 2>&1 || { echo >&2 "vault command not found. Please install Vault."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl command not found. Please install kubectl."; exit 1; }

# Set UP addresses
VAULT_ADDR=${VAULT_ADDR:-"https://hcvault-sandbox.llm-aws.com:8200"}
KUBE_API_SERVER=${KUBE_API_SERVER:-"https://3e77-152-231-192-172.ngrok-free.app "}
export VAULT_ADDR

# Fetch the current cluster name dynamically
CURRENT_CLUSTER_NAME=$(kubectl config current-context)

# Fetch the token
TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)

# Fetch Kubernetes CA Certificate
KUBE_CA_CERT=$(kubectl get secret -o jsonpath="{.data['ca\.crt']}" $(kubectl get sa default -o jsonpath="{.secrets[0].name}") | base64 --decode)

# Verify Vault connection
if ! vault status > /dev/null 2>&1; then
  echo "Could not connect to Vault at $VAULT_ADDR"
  exit 1
fi

# Check if Kubernetes authentication is already enabled for the specific cluster
if vault auth list | grep -q "$CURRENT_CLUSTER_NAME/"; then
  echo "Kubernetes auth for $CURRENT_CLUSTER_NAME is already enabled."
else
  echo "Enabling Kubernetes authentication for $CURRENT_CLUSTER_NAME..."
  if ! vault auth enable -path=$CURRENT_CLUSTER_NAME kubernetes; then
    echo "Failed to enable Kubernetes authentication for $CURRENT_CLUSTER_NAME in Vault."
    exit 1
  fi
fi

# Configure Kubernetes authentication
echo "Configuring Kubernetes authentication..."
if ! vault write auth/$CURRENT_CLUSTER_NAME/config \
      token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
      kubernetes_host="$KUBE_API_SERVER" \
      kubernetes_ca_cert="$KUBE_CA_CERT"; then
  echo "Failed to configure Kubernetes authentication in Vault."
  exit 1
fi

# Create Vault Policy
echo "Creating Vault policy..."
if ! vault policy write juan-vault-web-poc - <<EOF; then
path "devops/kv/vault-templating-poc/*" {
  capabilities = ["read", "list"]
}
EOF
  echo "Failed to create Vault policy."
  exit 1
fi

# Create Kubernetes Role
echo "Creating Kubernetes authentication role..."
if ! vault write auth/$CURRENT_CLUSTER_NAME/role/juan-vault-web-poc \
      bound_service_account_names=juan-vault-web-poc \
      bound_service_account_namespaces=default \
      policies=juan-vault-web-poc \
      ttl=24h; then
  echo "Failed to create Kubernetes authentication role in Vault."
  exit 1
fi


# Create ServiceAccount
echo "Creating ServiceAccount..."
if ! kubectl get serviceaccount juan-vault-web-poc > /dev/null 2>&1; then
  if ! kubectl create sa juan-vault-web-poc; then
    echo "Failed to create ServiceAccount."
    exit 1
  fi
else
  echo "Service account juan-vault-web-poc already exists, skipping creation"
fi

echo "Script execution complete."