#!/bin/bash

# Deploy VinDr Lab to k3s cluster
# This script will deploy all components in the correct order

set -e

NAMESPACE="vinlab"
MANIFESTS_DIR="../manifests"

echo "Deploying VinDr Lab to k3s..."

# Step 1: Create namespace
echo "Step 1: Creating namespace..."
kubectl apply -f ${MANIFESTS_DIR}/00-namespace.yaml

# Step 2: Create ConfigMaps
echo "Step 2: Creating ConfigMaps..."
cd "$(dirname "$0")"
./00-create-configmaps.sh

# Step 3: Deploy infrastructure services (ES, Redis, MinIO, Keycloak, Orthanc, RQLite)
echo "Step 3: Deploying infrastructure services..."
kubectl apply -f ${MANIFESTS_DIR}/01-elasticsearch.yaml
kubectl apply -f ${MANIFESTS_DIR}/02-redis.yaml
kubectl apply -f ${MANIFESTS_DIR}/03-minio.yaml
kubectl apply -f ${MANIFESTS_DIR}/04-keycloak.yaml
kubectl apply -f ${MANIFESTS_DIR}/05-orthanc.yaml
kubectl apply -f ${MANIFESTS_DIR}/06-rqlite.yaml

echo "Waiting for infrastructure services to be ready..."
sleep 30

# Step 4: Deploy ID Generator
echo "Step 4: Deploying ID Generator..."
kubectl apply -f ${MANIFESTS_DIR}/07-id-generator.yaml

sleep 10

# Step 5: Deploy application services
echo "Step 5: Deploying application services..."
kubectl apply -f ${MANIFESTS_DIR}/08-vinlab-api.yaml
kubectl apply -f ${MANIFESTS_DIR}/09-vinlab-uploader.yaml
kubectl apply -f ${MANIFESTS_DIR}/10-vinlab-dashboard.yaml
kubectl apply -f ${MANIFESTS_DIR}/11-vinlab-viewer.yaml

sleep 10

# Step 6: Deploy API Gateway
echo "Step 6: Deploying API Gateway..."
kubectl apply -f ${MANIFESTS_DIR}/12-apigateway.yaml

# Step 7: Deploy Ingress
echo "Step 7: Deploying Ingress..."
kubectl apply -f ${MANIFESTS_DIR}/13-ingress.yaml

echo ""
echo "Deployment completed!"
echo ""
echo "To check the status of your deployment:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl get svc -n ${NAMESPACE}"
echo "  kubectl get ingress -n ${NAMESPACE}"
echo ""
echo "To access the application:"
echo "  - Via NodePort: http://localhost:30080"
echo "  - Via Ingress: http://<your-k3s-server-ip>"
echo ""
echo "Note: You may need to configure Keycloak before using the system."
echo "See the main README.md for Keycloak setup instructions."
