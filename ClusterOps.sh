#!/bin/bash

# Script Name: ClusterOps.sh
# Author: Juan Monge
# Description: Deploy or destroy of k8s objects (yamls)

readonly yaml_files=(
    "manifests/configmaps/nginx-proxy-configmap.yaml"
    "manifests/configmaps/web-app-vault-template-configmap.yaml"
    "manifests/deployments/nginx-proxy-deployment.yaml"
    "manifests/deployments/web-app-deployment.yaml"
    "manifests/loadbalancer/nginx-proxy-loadbalancer.yaml"
    "manifests/service/nginx-proxy-service.yaml"
    "manifests/service/web-app-service.yaml"
    # Remove or correct the following line
    # "manifests/ingress/nginx-proxy-ingress.yaml"
)

# Function to redeploy YAML files
function redeploy_files {
    echo "Redeploying YAML files in the default namespace..."
    for filePath in "${yaml_files[@]}"; do
        kubectl apply -f "$filePath" --namespace=default || {
            echo "Error deploying YAML file: $filePath"
            exit 1
        }
    done
    echo "Pods, services, ingresses, and configmaps redeployed successfully!"
}

# Function to delete resources defined in YAML files
function delete_resources {
    echo "Deleting resources defined in YAML files in the default namespace..."
    for filePath in "${yaml_files[@]}"; do
        kubectl delete -f "$filePath" --namespace=default --ignore-not-found || {
            echo "Error deleting resources defined in YAML file: $filePath"
            exit 1
        }
        echo "Deleted resources defined in: $filePath"
    done
    echo "Resources defined in YAML files deleted successfully!"
}


# Prompt the user to choose an action
read -p "Do you want to delete the resources defined in YAML files (d), or redeploy (r) YAML files? (d/r): " choice

if [ "$choice" == "d" ]; then
    delete_resources
elif [ "$choice" == "r" ]; then
    redeploy_files
else
    echo "Invalid choice. Please choose 'd' to delete the resources defined in YAML files or 'r' to redeploy YAML files."
    exit 1
fi