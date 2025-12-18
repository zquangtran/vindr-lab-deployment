#!/bin/bash

# Undeploy VinDr Lab from k3s cluster
# This script will remove all components

set -e

NAMESPACE="vinlab"
MANIFESTS_DIR="../manifests"

echo "Undeploying VinDr Lab from k3s..."
echo "WARNING: This will delete all resources in the ${NAMESPACE} namespace!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Undeploy cancelled."
    exit 0
fi

# Delete all manifests
echo "Deleting all resources..."
kubectl delete -f ${MANIFESTS_DIR}/13-ingress.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/12-apigateway.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/11-vinlab-viewer.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/10-vinlab-dashboard.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/09-vinlab-uploader.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/08-vinlab-api.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/07-id-generator.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/06-rqlite.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/05-orthanc.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/04-keycloak.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/03-minio.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/02-redis.yaml --ignore-not-found=true
kubectl delete -f ${MANIFESTS_DIR}/01-elasticsearch.yaml --ignore-not-found=true

# Delete ConfigMaps
echo "Deleting ConfigMaps..."
kubectl delete configmap apigateway-configmap -n ${NAMESPACE} --ignore-not-found=true
kubectl delete configmap backend-configmap -n ${NAMESPACE} --ignore-not-found=true

# Optionally delete namespace (uncomment if you want to delete the namespace too)
# echo "Deleting namespace..."
# kubectl delete -f ${MANIFESTS_DIR}/00-namespace.yaml

echo ""
echo "Undeploy completed!"
echo ""
echo "Note: The namespace '${NAMESPACE}' was not deleted."
echo "To delete the namespace and all PVCs, run:"
echo "  kubectl delete namespace ${NAMESPACE}"
