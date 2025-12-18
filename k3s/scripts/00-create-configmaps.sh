#!/bin/bash

# Script to create ConfigMaps for VinDr Lab on k3s
# This script should be run before deploying the application

set -e

NAMESPACE="vinlab"
CONFIG_DIR="../config/vinlab-configmap"

echo "Creating ConfigMaps for VinDr Lab..."

# Create namespace if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Delete existing configmaps if they exist
echo "Cleaning up existing ConfigMaps..."
kubectl delete configmap apigateway-configmap -n ${NAMESPACE} --ignore-not-found=true
kubectl delete configmap backend-configmap -n ${NAMESPACE} --ignore-not-found=true

# Create API Gateway (nginx) ConfigMap
echo "Creating API Gateway ConfigMap..."
kubectl create configmap apigateway-configmap \
  --from-file=${CONFIG_DIR}/nginx.conf \
  -n ${NAMESPACE}

# Create Backend ConfigMap
echo "Creating Backend ConfigMap..."
kubectl create configmap backend-configmap \
  --from-file=${CONFIG_DIR}/backend/ \
  -n ${NAMESPACE}

echo "ConfigMaps created successfully!"
echo ""
echo "To verify, run:"
echo "  kubectl get configmap -n ${NAMESPACE}"
