# kubectl Cheat Sheet for testkube-fun

Quick reference for common Kubernetes operations with this application.

## Basic Operations

### Get Resources
```bash
# Get all resources
kubectl get all

# Get specific resources
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get configmaps
kubectl get secrets

# Get resources with labels
kubectl get pods -l app=api
kubectl get pods -l app=web
kubectl get pods -l app=postgres

# Get resources with detailed output
kubectl get pods -o wide
kubectl get services -o yaml
```

### Describe Resources
```bash
# Get detailed information
kubectl describe pod <pod-name>
kubectl describe service <service-name>
kubectl describe deployment <deployment-name>

# Describe all pods for an app
kubectl describe pods -l app=api
```

## Application-Specific Commands

### Logs
```bash
# View logs for all API pods
kubectl logs -l app=api -f

# View logs for all web pods  
kubectl logs -l app=web -f

# View logs for database
kubectl logs -l app=postgres -f

# View logs for specific pod
kubectl logs <pod-name> -f

# View previous logs (if pod restarted)
kubectl logs <pod-name> --previous
```

### Port Forwarding
```bash
# Forward web service to local port 8080
kubectl port-forward svc/web-service 8080:80

# Forward API service to local port 3000
kubectl port-forward svc/api-service 3000:8080

# Forward database to local port 5432
kubectl port-forward svc/postgres-service 5432:5432

# Forward specific pod
kubectl port-forward pod/<pod-name> 8080:8080
```

### Execute Commands in Pods
```bash
# Get shell access to API pod
kubectl exec -it deployment/api-deployment -- /bin/bash

# Get shell access to database pod
kubectl exec -it deployment/postgres-deployment -- /bin/bash

# Run PostgreSQL client in database pod
kubectl exec -it deployment/postgres-deployment -- psql -U api-user -d api-db

# Run one-off command
kubectl exec deployment/api-deployment -- npm --version
```

## Scaling and Updates

### Scaling
```bash
# Scale API deployment
kubectl scale deployment api-deployment --replicas=3

# Scale web deployment
kubectl scale deployment web-deployment --replicas=2

# Get current replica count
kubectl get deployment api-deployment
```

### Rolling Updates
```bash
# Update image for API deployment
kubectl set image deployment/api-deployment api=testkube-fun-api:v2.0.0

# Update image for web deployment  
kubectl set image deployment/web-deployment web=testkube-fun-web:v2.0.0

# Check rollout status
kubectl rollout status deployment/api-deployment

# View rollout history
kubectl rollout history deployment/api-deployment

# Rollback to previous version
kubectl rollout undo deployment/api-deployment

# Rollback to specific revision
kubectl rollout undo deployment/api-deployment --to-revision=2
```

### Restart Deployments
```bash
# Restart API deployment
kubectl rollout restart deployment/api-deployment

# Restart web deployment
kubectl rollout restart deployment/web-deployment

# Restart database deployment
kubectl rollout restart deployment/postgres-deployment
```

## Configuration Management

### ConfigMaps and Secrets
```bash
# View ConfigMap contents
kubectl get configmap postgres-config -o yaml

# Edit ConfigMap
kubectl edit configmap postgres-config

# View Secret (base64 encoded)
kubectl get secret postgres-secret -o yaml

# Decode secret value
kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d

# Create secret from command line
kubectl create secret generic my-secret --from-literal=key=value

# Update secret
kubectl patch secret postgres-secret -p='{"data":{"POSTGRES_PASSWORD":"bmV3LXBhc3N3b3Jk"}}'
```

### Environment Variables
```bash
# View environment variables in pod
kubectl exec deployment/api-deployment -- env

# View specific environment variable
kubectl exec deployment/api-deployment -- printenv DB_HOST
```

## Troubleshooting

### Pod Issues
```bash
# Get pod events
kubectl get events --field-selector involvedObject.name=<pod-name>

# Get events sorted by time
kubectl get events --sort-by=.metadata.creationTimestamp

# Check pod resource usage
kubectl top pod <pod-name>

# Check node resource usage
kubectl top nodes

# Get pod YAML for debugging
kubectl get pod <pod-name> -o yaml
```

### Network Issues
```bash
# Test service connectivity from within cluster
kubectl run debug --image=busybox:1.35 --rm -it --restart=Never -- /bin/sh

# Inside the debug pod:
# nslookup api-service
# wget -qO- http://api-service:8080/health
# nc -zv postgres-service 5432

# Check service endpoints
kubectl get endpoints api-service
kubectl get endpoints web-service
kubectl get endpoints postgres-service

# Describe service for troubleshooting
kubectl describe service api-service
```

### Resource Usage
```bash
# Check resource usage for all pods
kubectl top pods

# Check resource usage for specific app
kubectl top pods -l app=api

# Check node resource usage
kubectl top nodes

# Get resource requests and limits
kubectl describe deployment api-deployment | grep -A 10 "Limits\|Requests"
```

## Monitoring and Health Checks

### Health Status
```bash
# Check deployment health
kubectl get deployments

# Check pod readiness
kubectl get pods -l app=api -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready

# Check service health via endpoints
kubectl get endpoints
```

### Application Health
```bash
# Test API health endpoint (if available)
kubectl exec deployment/api-deployment -- curl -f http://localhost:8080/health

# Test web application
kubectl exec deployment/web-deployment -- curl -f http://localhost:4173/

# Test database connectivity
kubectl exec deployment/postgres-deployment -- pg_isready -U api-user -d api-db
```

## Namespace Operations

### Working with Namespaces
```bash
# Create namespace
kubectl create namespace testkube-fun-staging

# Deploy to specific namespace
kubectl apply -f k8s/ -n testkube-fun-staging

# Set default namespace for session
kubectl config set-context --current --namespace=testkube-fun-staging

# Get resources from all namespaces
kubectl get pods --all-namespaces

# Get resources from specific namespace
kubectl get pods -n testkube-fun-staging
```

## Backup and Recovery

### Database Backup
```bash
# Create database backup
kubectl exec deployment/postgres-deployment -- pg_dump -U api-user api-db > backup.sql

# Restore database backup
kubectl exec -i deployment/postgres-deployment -- psql -U api-user -d api-db < backup.sql
```

### Configuration Backup
```bash
# Export all configurations
kubectl get configmaps -o yaml > configmaps-backup.yaml
kubectl get secrets -o yaml > secrets-backup.yaml

# Export specific resources
kubectl get -o yaml deployment,service,configmap,secret -l app=testkube-fun > app-backup.yaml
```

## Useful Aliases

Add these to your shell profile for faster operations:

```bash
# Basic aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'

# Application-specific aliases
alias klapi='kubectl logs -l app=api -f'
alias klweb='kubectl logs -l app=web -f'
alias kldb='kubectl logs -l app=postgres -f'

# Port forwarding aliases
alias pfweb='kubectl port-forward svc/web-service 8080:80'
alias pfapi='kubectl port-forward svc/api-service 3000:8080'
alias pfdb='kubectl port-forward svc/postgres-service 5432:5432'

# Quick access aliases
alias apiexec='kubectl exec -it deployment/api-deployment -- /bin/bash'
alias webexec='kubectl exec -it deployment/web-deployment -- /bin/bash'
alias dbexec='kubectl exec -it deployment/postgres-deployment -- /bin/bash'
```

## Emergency Procedures

### Pod is Crashing
```bash
# Check pod status and events
kubectl describe pod <pod-name>

# Check logs for errors
kubectl logs <pod-name> --previous

# Check resource limits
kubectl describe deployment <deployment-name>

# Scale down to 0 and back up
kubectl scale deployment <deployment-name> --replicas=0
kubectl scale deployment <deployment-name> --replicas=1
```

### Service Not Accessible
```bash
# Check service and endpoints
kubectl get service <service-name>
kubectl get endpoints <service-name>

# Check pod labels match service selector
kubectl get pods --show-labels
kubectl describe service <service-name>

# Test from within cluster
kubectl run debug --image=busybox:1.35 --rm -it --restart=Never -- /bin/sh
```

### Database Issues
```bash
# Check database pod status
kubectl get pods -l app=postgres

# Check database logs
kubectl logs -l app=postgres -f

# Check persistent volume
kubectl get pv,pvc

# Access database directly
kubectl exec -it deployment/postgres-deployment -- psql -U api-user -d api-db
```

## Quick Reference

| Operation | Command |
|-----------|---------|
| View all pods | `kubectl get pods` |
| View pod logs | `kubectl logs <pod-name> -f` |
| Access pod shell | `kubectl exec -it <pod-name> -- /bin/bash` |
| Port forward | `kubectl port-forward svc/<service> <local>:<remote>` |
| Scale deployment | `kubectl scale deployment <name> --replicas=<n>` |
| Update image | `kubectl set image deployment/<name> <container>=<image>` |
| Restart deployment | `kubectl rollout restart deployment/<name>` |
| View events | `kubectl get events --sort-by=.metadata.creationTimestamp` |
| Describe resource | `kubectl describe <resource> <name>` |
| Delete resource | `kubectl delete <resource> <name>` |