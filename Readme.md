# Project Execution Guide

This guide provides a comprehensive step-by-step walkthrough for configuring and deploying the VaultSideCar Injector. Follow the instructions below to set up the environment and deploy the necessary components.

## Project Map

```
kubernetes_project
|
├── ClusterOps.sh
├── assets/
│   ├── myapp-policy.hcl
|
├── configure_vault_sidecar.sh
├── helm/
│   ├── deploy-vault-helm.sh
│   ├── vault-values.yaml
|
├── manifests/
│   ├── configmaps/
│   │   ├── nginx-proxy-configmap.yaml
│   │   ├── web-app-vault-template-configmap.yaml
│   ├── deployments/
│   │   ├── nginx-proxy-deployment.yaml
│   │   ├── web-app-deployment.yaml
│   ├── loadbalancer/
│   │   ├── nginx-proxy-loadbalancer.yaml
│   ├── service/
│   │   ├── nginx-proxy-service.yaml
│   │   ├── web-app-service.yaml
|
└── visualmap.ascii
```

## Step 1: Deploy or Destroy Kubernetes Objects (including Nginx Proxy and Web Application)

This step involves deploying or destroying Kubernetes objects such as the Nginx proxy and web application.

### Execution:

```bash
./ClusterOps.sh
```

### Details:

- **Redeploy YAML Files**: Applies the defined YAML files to redeploy pods, services, ingresses, and configmaps.
- **Delete Resources**: Deletes the resources defined in the YAML files.
- **User Prompt**: Asks the user whether to delete or redeploy the resources.

## Step 2: Configure Vault Sidecar with Kubernetes Authentication
This step involves setting up Kubernetes authentication with Vault and integrating the Vault Sidecar Injector.

### Set up you local Vault env

1. connect to vpn
2. export VAULT_ADDR=https://hcvault-sandbox.llm-aws.com:8200/ # Replace with your Vault Server URL

### Execution:

```bash
./configure_vault_sidecar.sh
```

### Details:

- **Obtain Kubernetes Information**: Retrieves the Kubernetes API server URL and client CA file.
- **Create Kubernetes Service Account**: Creates a service account named `vault-auth`.
- **Configure Kubernetes Authentication in Vault**: Writes the Kubernetes authentication configuration to Vault.
- **Create a Vault Policy**: Defines a policy with read capabilities.
- **Create a Role in Vault**: Binds the service account to the policy and sets a time-to-live (TTL).
- **Verify the Integration**: Checks the logs from the Vault sidecar container to verify the integration.

## Step 3: Deploy Vault using Helm

This step involves deploying Vault using Helm, including adding the HashiCorp Helm repository and managing the Vault Helm release.

### Execution:

```bash
./helm/deploy-vault-helm.sh
```

### Details:

- **Add and Update HashiCorp Helm Repository**: Ensures the HashiCorp Helm repository is added and updated.
- **Check Vault Helm Installation Status**: Verifies the status of the existing Vault Helm installation.
- **Deploy or Redeploy Vault Helm**: Installs or reinstalls the Vault Helm release based on the provided values file.

## Step 4: Verify the Deployment

This step involves verifying the deployment by inspecting the logs and status of the deployed resources.

### Execution:

Use standard Kubernetes commands to inspect the deployed resources:

```bash
kubectl get pods
kubectl describe <resource_type> <resource_name>
kubectl logs <pod_name>
```

### Details:

- **Inspect Pods**: Check the status of the deployed pods to ensure they are running.
- **Inspect Services and Load Balancers**: Verify the services and load balancers are properly configured.
- **Check Logs**: Review the logs of the deployed containers for any errors or warnings.

Certainly! Here's the complete guide, covering how to install ngrok, run it against a specific port, and how to query the Kubernetes API server address on a Mac.

---

# Query Kubernetes API Server Address

1. Open a new Terminal window.

2. Run the following command to get the API server address:

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

3. The command will return the Kubernetes API server address, for example:

```bash
https://127.0.0.1:6443
```

You can use this address for configurations that require the Kubernetes API server address, such as setting up Vault or other third-party services.


# Ngrok Installation and Configuration Guide for Mac

## Install Homebrew (if not already installed)

1. Open a new Terminal window.

2. Run the following command to install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Follow the on-screen instructions to complete the installation.

## Install Ngrok

1. After installing Homebrew, install ngrok by running:

```bash
brew install ngrok
```

## Run Ngrok

1. To run ngrok against a specific port (e.g., 6443), open a new Terminal window and type:

```bash
ngrok http 6443
```

2. This will give you a public URL that forwards to your local server. Look for a line like:

```text
Forwarding https://your-ngrok-subdomain.ngrok.io -> http://localhost:6443
```

3. Note down the public URL (e.g., `https://your-ngrok-subdomain.ngrok.io`); you'll use this for configurations.
