#!/bin/bash

# Kubernetes Deployment Script for testkube-fun
# This script deploys the entire application stack to Kubernetes

set -e

echo "🚀 Starting Kubernetes deployment for testkube-fun..."

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

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment_name=$1
    local namespace=${2:-default}

    echo "⏳ Waiting for deployment $deployment_name to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment_name -n $namespace

    if [ $? -eq 0 ]; then
        echo "✅ Deployment $deployment_name is ready"
    else
        echo "❌ Deployment $deployment_name failed to become ready"
        exit 1
    fi
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📁 Using manifests from: $SCRIPT_DIR"

# Deploy database resources first
echo "🗄️  Deploying database resources..."
kubectl apply -f "$SCRIPT_DIR/database-configmap.yaml"
kubectl apply -f "$SCRIPT_DIR/database-secret.yaml"
kubectl apply -f "$SCRIPT_DIR/database-pvc.yaml"
kubectl apply -f "$SCRIPT_DIR/database-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/database-service.yaml"

# Wait for database to be ready
wait_for_deployment "postgres-deployment"

# Deploy API resources
echo "🔧 Deploying API resources..."
kubectl apply -f "$SCRIPT_DIR/api-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/api-service.yaml"

# Wait for API to be ready
wait_for_deployment "api-deployment"

# Deploy web resources
echo "🌐 Deploying web resources..."
kubectl apply -f "$SCRIPT_DIR/web-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/web-service.yaml"

# Wait for web to be ready
wait_for_deployment "web-deployment"

# Deploy ingress (optional)
if [ -f "$SCRIPT_DIR/ingress.yaml" ]; then
    echo "🌍 Deploying ingress..."
    kubectl apply -f "$SCRIPT_DIR/ingress.yaml"
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Current status:"
kubectl get pods -l app=postgres
kubectl get pods -l app=api
kubectl get pods -l app=web
echo ""
kubectl get services
echo ""

# Get external access information
echo "🔗 Access information:"
echo ""

# Check if LoadBalancer service exists and get external IP
WEB_EXTERNAL_IP=$(kubectl get svc web-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ -z "$WEB_EXTERNAL_IP" ]; then
    WEB_EXTERNAL_IP=$(kubectl get svc web-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
fi

if [ "$WEB_EXTERNAL_IP" != "pending" ] && [ -n "$WEB_EXTERNAL_IP" ]; then
    echo "🌐 Web application: http://$WEB_EXTERNAL_IP"
    echo "🔧 API endpoint: http://$WEB_EXTERNAL_IP/api"
else
    echo "⏳ External IP is pending. You can access the application using port-forward:"
    echo "   kubectl port-forward svc/web-service 8080:80"
    echo "   Then visit: http://localhost:8080"
fi

echo ""
echo "📋 Useful commands:"
echo "   View logs: kubectl logs -l app=<app-name> -f"
echo "   Scale deployment: kubectl scale deploy/<deployment-name> --replicas=<number>"
echo "   Delete deployment: kubectl delete -f $SCRIPT_DIR/"
echo "   Port forward: kubectl port-forward svc/<service-name> <local-port>:<service-port>"
echo ""
echo "✨ Happy coding!"
