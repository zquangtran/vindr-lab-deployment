#!/bin/bash

# Check the status of VinDr Lab deployment on k3s

set -e

NAMESPACE="vinlab"

echo "VinDr Lab Deployment Status"
echo "=============================="
echo ""

# Check if namespace exists
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo "Namespace '${NAMESPACE}' does not exist. VinDr Lab is not deployed."
    exit 1
fi

echo "Pods Status:"
echo "------------"
kubectl get pods -n ${NAMESPACE}
echo ""

echo "Services:"
echo "---------"
kubectl get svc -n ${NAMESPACE}
echo ""

echo "Ingress:"
echo "--------"
kubectl get ingress -n ${NAMESPACE}
echo ""

echo "Persistent Volume Claims:"
echo "-------------------------"
kubectl get pvc -n ${NAMESPACE}
echo ""

echo "ConfigMaps:"
echo "-----------"
kubectl get configmap -n ${NAMESPACE}
echo ""

# Check for pods that are not running
NOT_RUNNING=$(kubectl get pods -n ${NAMESPACE} --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
if [ "$NOT_RUNNING" -gt 0 ]; then
    echo "WARNING: There are ${NOT_RUNNING} pod(s) not in Running state!"
    echo ""
    kubectl get pods -n ${NAMESPACE} --field-selector=status.phase!=Running
fi
