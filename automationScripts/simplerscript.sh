
VAULT_ADDR=${VAULT_ADDR:-"https://hcvault-sandbox.llm-aws.com:8200"}
export VAULT_ADDR

# 1. Extract the values needed to configure the K8s-Vault integration 

# Get the name of the Vault secret used by Helm
VAULT_HELM_SECRET_NAME=$(kubectl get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')

# Get the JWT token from the Vault secret and decode it
TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)

# Get the CA certificate and decode it
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)

# Get the Kubernetes host URL
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')

# Check if required tools are installed
command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl is required but not installed. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but not installed. Aborting."; exit 1; }
command -v base64 >/dev/null 2>&1 || { echo >&2 "base64 is required but not installed. Aborting."; exit 1; }
command -v vault >/dev/null 2>&1 || { echo >&2 "vault is required but not installed. Aborting."; exit 1; }

# 2. Enable K8s cluster - Vault Authentication

# Enable Kubernetes authentication in Vault
vault auth enable -path=juan-vault-web-poc kubernetes

# Configure the Kubernetes authentication method in Vault
vault write auth/juan-vault-web-poc/config \
     token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
     kubernetes_host="$KUBE_HOST" \
     kubernetes_ca_cert="$KUBE_CA_CERT" \
     issuer="https://kubernetes.default.svc.cluster.local"

# 3. Create a Vault policy to specify permissions for the secret store above

# Write a policy in Vault that allows reading the specified secret path
vault policy write juan-vault-web-poc-policy - <<EOF
path "secret/data/juan-vault-web-poc/config" {
  capabilities = ["read"]
}
EOF

# 4. Create a Kubernetes authentication role for a specific K8s namespace and K8s service account

# Create a Kubernetes service account
kubectl create sa juan-vault-web-poc-policy

# Bind the created service account to the Kubernetes role
kubectl create clusterrolebinding juan-vault-web-poc-role-binding --clusterrole=edit --serviceaccount=default:juan-vault-web-poc-policy
