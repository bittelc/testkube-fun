#!/bin/bash

# Kubernetes Cleanup Script for testkube-fun
# This script removes all deployed resources from the Kubernetes cluster

set -e

echo "🧹 Starting cleanup of testkube-fun Kubernetes resources..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📁 Using manifests from: $SCRIPT_DIR"

# Function to safely delete resources
safe_delete() {
    local resource=$1
    if kubectl get $resource &> /dev/null; then
        echo "🗑️  Deleting $resource..."
        kubectl delete -f "$SCRIPT_DIR/$resource" --ignore-not-found=true
    else
        echo "ℹ️  Resource $resource not found, skipping..."
    fi
}

# Confirm deletion
echo ""
echo "⚠️  This will delete ALL testkube-fun resources from the current Kubernetes context:"
kubectl config current-context
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo ""
echo "🗑️  Starting resource cleanup..."

# Delete resources in reverse order of dependencies
echo "🌍 Removing ingress..."
safe_delete "ingress.yaml"

echo "🌐 Removing web resources..."
safe_delete "web-service.yaml"
safe_delete "web-deployment.yaml"

echo "🔧 Removing API resources..."
safe_delete "api-service.yaml"
safe_delete "api-deployment.yaml"

echo "🗄️  Removing database resources..."
safe_delete "database-service.yaml"
safe_delete "database-deployment.yaml"
safe_delete "database-pvc.yaml"
safe_delete "database-secret.yaml"
safe_delete "database-configmap.yaml"

# Wait a moment for resources to be deleted
echo "⏳ Waiting for resources to be fully deleted..."
sleep 5

# Check for any remaining resources
echo ""
echo "🔍 Checking for remaining resources..."

REMAINING_PODS=$(kubectl get pods -l "app in (postgres,api,web)" --no-headers 2>/dev/null | wc -l || echo "0")
REMAINING_SERVICES=$(kubectl get services -l "app in (postgres,api,web)" --no-headers 2>/dev/null | wc -l || echo "0")
REMAINING_DEPLOYMENTS=$(kubectl get deployments -l "app in (postgres,api,web)" --no-headers 2>/dev/null | wc -l || echo "0")

if [ "$REMAINING_PODS" -eq 0 ] && [ "$REMAINING_SERVICES" -eq 0 ] && [ "$REMAINING_DEPLOYMENTS" -eq 0 ]; then
    echo "✅ All testkube-fun resources have been successfully removed!"
else
    echo "⚠️  Some resources may still be terminating:"
    echo "   Pods: $REMAINING_PODS"
    echo "   Services: $REMAINING_SERVICES"
    echo "   Deployments: $REMAINING_DEPLOYMENTS"
    echo ""
    echo "💡 You can check the status with:"
    echo "   kubectl get all -l 'app in (postgres,api,web)'"
fi

echo ""
echo "🎯 Cleanup completed!"
echo ""
echo "📋 If you need to check for any remaining resources:"
echo "   kubectl get all --all-namespaces | grep testkube"
echo "   kubectl get pv | grep postgres"
echo ""
echo "✨ All done!"
