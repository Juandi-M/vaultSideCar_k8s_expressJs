#!/bin/bash

# Define an array of folder paths containing YAML files
declare -a yaml_folders=(
    "manifests/configmaps/nginx-proxy-configmap.yaml"
    "manifests/configmaps/web-app-vault-template-configmap.yaml"
    "manifests/deployments/nginx-proxy-deployment.yaml"
    "manifests/deployments/web-app-deployment.yaml"
    "manifests/loadbalancer/nginx-proxy-loadbalancer.yaml"
    "manifests/service/nginx-proxy-service.yaml"
    "manifests/service/web-app-service.yaml"
)

# Function to redeploy YAML files in a folder
function redeploy_folder {
    folder_path=$1
    echo "Redeploying YAML files in folder: $folder_path"
    kubectl apply -f "$folder_path"
}

# Delete all pods in the default namespace
kubectl delete pods --all

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
sleep 10

# Iterate through the array and redeploy YAML files in each folder
for folder in "${yaml_folders[@]}"; do
    redeploy_folder "$folder"
done

echo "Pods redeployed successfully!"