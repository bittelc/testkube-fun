# Kubernetes Deployment Guide

This directory contains Kubernetes manifests and deployment scripts for the testkube-fun application stack.

## Architecture Overview

The application consists of three main components:

- **Web Frontend** - Node.js/Vite application serving the user interface
- **API Backend** - Node.js API server handling business logic
- **PostgreSQL Database** - Data persistence layer

## Prerequisites

Before deploying, ensure you have:

1. **Kubernetes Cluster** - A running Kubernetes cluster (local or cloud)
2. **kubectl** - Kubernetes command-line tool configured to access your cluster
3. **Container Images** - Built and tagged Docker images for your applications

### Building Container Images

Before deployment, you need to build and tag your container images:

```bash
# Build API image
docker build -f apps/api/Dockerfile -t testkube-fun-api:latest .

# Build Web image
docker build -f apps/web/Dockerfile -t testkube-fun-web:latest .
```

If using a remote registry (recommended for production):

```bash
# Tag and push to your registry
docker tag testkube-fun-api:latest your-registry.com/testkube-fun-api:latest
docker tag testkube-fun-web:latest your-registry.com/testkube-fun-web:latest

docker push your-registry.com/testkube-fun-api:latest
docker push your-registry.com/testkube-fun-web:latest
```

**Note**: Update the image references in the deployment files if using a remote registry.

## Quick Start

### Automated Deployment

Use the provided deployment script for a complete setup:

```bash
./k8s/deploy.sh
```

This script will:
- Deploy all Kubernetes resources in the correct order
- Wait for each component to be ready before proceeding
- Provide access information once deployment is complete

### Manual Deployment

If you prefer to deploy manually:

```bash
# 1. Deploy database resources
kubectl apply -f k8s/database-configmap.yaml
kubectl apply -f k8s/database-secret.yaml
kubectl apply -f k8s/database-pvc.yaml
kubectl apply -f k8s/database-deployment.yaml
kubectl apply -f k8s/database-service.yaml

# 2. Wait for database to be ready
kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment

# 3. Deploy API resources
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/api-service.yaml

# 4. Wait for API to be ready
kubectl wait --for=condition=available --timeout=300s deployment/api-deployment

# 5. Deploy web resources
kubectl apply -f k8s/web-deployment.yaml
kubectl apply -f k8s/web-service.yaml

# 6. Deploy ingress (optional)
kubectl apply -f k8s/ingress.yaml
```

## Resource Descriptions

### Database Resources

- **`database-configmap.yaml`** - Configuration for PostgreSQL database
- **`database-secret.yaml`** - Sensitive data (passwords) for database
- **`database-pvc.yaml`** - Persistent storage claim for database data
- **`database-deployment.yaml`** - PostgreSQL database deployment with health checks
- **`database-service.yaml`** - Internal service for database connectivity

### API Resources

- **`api-deployment.yaml`** - Backend API deployment with scaling and health checks
- **`api-service.yaml`** - Internal service for API connectivity

### Web Resources

- **`web-deployment.yaml`** - Frontend web deployment with scaling
- **`web-service.yaml`** - LoadBalancer service for external web access

### Network Resources

- **`ingress.yaml`** - Ingress controller configuration for external access (optional)

## Accessing the Application

### Via LoadBalancer

If your cluster supports LoadBalancer services:

```bash
# Get external IP
kubectl get svc web-service

# Access the application
curl http://<EXTERNAL-IP>
```

### Via Port Forwarding

For local development or clusters without LoadBalancer support:

```bash
# Forward web service
kubectl port-forward svc/web-service 8080:80

# Access at http://localhost:8080
```

### Via Ingress

If using the ingress configuration:

1. Ensure you have an ingress controller (like NGINX) installed
2. Add the following to your `/etc/hosts` file:
   ```
   <INGRESS-IP> testkube-fun.local
   ```
3. Access at `http://testkube-fun.local`

## Configuration

### Environment Variables

The application uses the following environment variables:

#### API Container
- `DB_HOST` - Database hostname (set to `postgres-service`)
- `DB_PORT` - Database port (set to `5432`)
- `POSTGRES_DB` - Database name
- `POSTGRES_USER` - Database username
- `POSTGRES_PASSWORD` - Database password

#### Web Container
- `API_URL` - API service URL (set to `http://api-service:8080`)

### Secrets Management

Database credentials are stored in Kubernetes secrets. To update the password:

```bash
# Create new password (base64 encoded)
echo -n 'your-new-password' | base64

# Update the secret
kubectl patch secret postgres-secret -p='{"data":{"POSTGRES_PASSWORD":"<base64-encoded-password>"}}'

# Restart deployments to pick up new secret
kubectl rollout restart deployment/postgres-deployment
kubectl rollout restart deployment/api-deployment
```

### Scaling

Scale deployments based on load:

```bash
# Scale API
kubectl scale deployment api-deployment --replicas=3

# Scale Web
kubectl scale deployment web-deployment --replicas=3

# Database should remain at 1 replica for data consistency
```

## Monitoring and Troubleshooting

### Viewing Logs

```bash
# View all pods
kubectl get pods

# View logs for specific application
kubectl logs -l app=api -f
kubectl logs -l app=web -f
kubectl logs -l app=postgres -f

# View logs for specific pod
kubectl logs <pod-name> -f
```

### Health Checks

All services include health checks:

```bash
# Check deployment status
kubectl get deployments

# Check pod health
kubectl describe pod <pod-name>

# Check service endpoints
kubectl get endpoints
```

### Common Issues

1. **ImagePullBackOff**: Ensure container images are built and accessible
2. **Database Connection Issues**: Check if postgres-deployment is ready
3. **Resource Limits**: Adjust CPU/memory limits in deployment files
4. **Storage Issues**: Verify PVC is bound and storage class exists

### Debugging Commands

```bash
# Get detailed information about resources
kubectl describe deployment <deployment-name>
kubectl describe pod <pod-name>
kubectl describe service <service-name>

# Execute commands in containers
kubectl exec -it <pod-name> -- /bin/bash

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Production Considerations

### Security

1. **Update default passwords** in `database-secret.yaml`
2. **Use image tags** instead of `latest` for production
3. **Enable RBAC** and create service accounts with minimal permissions
4. **Use network policies** to restrict inter-pod communication
5. **Scan images** for vulnerabilities before deployment

### Performance

1. **Resource limits**: Set appropriate CPU/memory limits
2. **Horizontal Pod Autoscaler**: Configure HPA for automatic scaling
3. **Database optimization**: Tune PostgreSQL configuration
4. **Persistent volumes**: Use appropriate storage classes for performance

### High Availability

1. **Multi-replica deployments**: Run multiple instances of API and web
2. **Pod disruption budgets**: Ensure availability during updates
3. **Database clustering**: Consider PostgreSQL clustering for HA
4. **Load balancing**: Distribute traffic across replicas

### Monitoring

Consider implementing:

1. **Prometheus + Grafana** for metrics and dashboards
2. **Elasticsearch + Kibana** for log aggregation
3. **Jaeger** for distributed tracing
4. **Health check endpoints** in your applications

## Cleanup

To remove all deployed resources:

```bash
./k8s/cleanup.sh
```

Or manually:

```bash
kubectl delete -f k8s/
```

## Customization

### Using Different Namespaces

To deploy to a specific namespace:

```bash
# Create namespace
kubectl create namespace testkube-fun

# Deploy with namespace
kubectl apply -f k8s/ -n testkube-fun
```

### Using Different Storage Classes

Update `database-pvc.yaml` to use your preferred storage class:

```yaml
spec:
  storageClassName: your-storage-class
```

### Custom Domain Names

Update `ingress.yaml` with your domain:

```yaml
spec:
  rules:
  - host: your-domain.com
```

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review Kubernetes events: `kubectl get events`
3. Check application logs: `kubectl logs -l app=<app-name>`
4. Consult the main project README for application-specific issues

## Contributing

When modifying Kubernetes manifests:

1. Test changes in a development environment first
2. Update this README if adding new resources or changing deployment procedures
3. Validate YAML syntax: `kubectl apply --dry-run=client -f <file>`
4. Follow Kubernetes best practices for resource naming and labeling