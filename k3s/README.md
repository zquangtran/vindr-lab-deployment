# VinDr Lab - K3s Deployment

This directory contains the deployment files and scripts for deploying VinDr Lab on k3s (lightweight Kubernetes).

## Prerequisites

1. **k3s installed**: Install k3s on your system
   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```

2. **kubectl configured**: k3s automatically configures kubectl
   ```bash
   # For non-root users
   sudo chmod 644 /etc/rancher/k3s/k3s.yaml
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   ```

3. **System Requirements**: At least 4GB of RAM for optimal performance

## Quick Start

### 1. Deploy VinDr Lab

Navigate to the scripts directory and run the deployment script:

```bash
cd k3s/scripts
./01-deploy.sh
```

This script will:
- Create the `vinlab` namespace
- Create necessary ConfigMaps
- Deploy all infrastructure services (Elasticsearch, Redis, MinIO, Keycloak, Orthanc, RQLite)
- Deploy application services (API, Uploader, Dashboard, Viewer)
- Deploy API Gateway (nginx)
- Deploy Ingress (Traefik)

### 2. Check Deployment Status

```bash
./03-status.sh
```

Or manually:
```bash
kubectl get pods -n vinlab
kubectl get svc -n vinlab
kubectl get ingress -n vinlab
```

### 3. Access the Application

#### Via NodePort (recommended for local development):
```
http://localhost:30080
```

#### Via Ingress:
```
http://<your-k3s-server-ip>
```

## Directory Structure

```
k3s/
├── manifests/          # Kubernetes manifest files
│   ├── 00-namespace.yaml
│   ├── 01-elasticsearch.yaml
│   ├── 02-redis.yaml
│   ├── 03-minio.yaml
│   ├── 04-keycloak.yaml
│   ├── 05-orthanc.yaml
│   ├── 06-rqlite.yaml
│   ├── 07-id-generator.yaml
│   ├── 08-vinlab-api.yaml
│   ├── 09-vinlab-uploader.yaml
│   ├── 10-vinlab-dashboard.yaml
│   ├── 11-vinlab-viewer.yaml
│   ├── 12-apigateway.yaml
│   └── 13-ingress.yaml
├── scripts/            # Deployment scripts
│   ├── 00-create-configmaps.sh
│   ├── 01-deploy.sh
│   ├── 02-undeploy.sh
│   └── 03-status.sh
├── config/             # Configuration files
│   └── vinlab-configmap/
└── README.md          # This file
```

## Component Details

### Infrastructure Services

1. **Elasticsearch** (5Gi storage)
   - Index and search engine for DICOM studies
   - Exposed on port 9200

2. **Redis**
   - Cache and session store
   - Exposed on port 6379

3. **MinIO** (10Gi storage)
   - Object storage for exported labels
   - API port: 9000, Console port: 9001

4. **Keycloak** (2Gi storage)
   - Authentication and authorization
   - Exposed on port 8080

5. **Orthanc** (10Gi storage)
   - DICOM server
   - DICOM port: 4242, Web port: 8042

6. **RQLite** (2Gi storage)
   - Distributed database for ID generation
   - HTTP port: 4001, Raft port: 4002

### Application Services

1. **ID Generator**
   - Generates unique IDs for studies and projects

2. **VinLab API**
   - Main backend API service

3. **VinLab Uploader**
   - DICOM upload service

4. **VinLab Dashboard**
   - Main web interface

5. **VinLab Viewer**
   - Medical image viewer

6. **API Gateway (nginx)**
   - Routes requests to appropriate services
   - Single entry point for the application

## Storage

All persistent volumes use k3s's built-in `local-path` storage class, which stores data in `/var/lib/rancher/k3s/storage/` by default.

## Configuration

### ConfigMaps

Two ConfigMaps are created:
1. `apigateway-configmap` - nginx configuration
2. `backend-configmap` - backend application configuration

To update ConfigMaps:
```bash
cd k3s/scripts
./00-create-configmaps.sh
```

### Environment Variables

Edit the manifest files in `k3s/manifests/` to customize environment variables for each service.

Important variables to configure:
- **API Key**: Set `WEBSERVER__API_KEY` and `APP_VINDR_LAB_API_KEY`
- **Base URL**: Update `SERVER_BASE_URL` in dashboard and viewer deployments
- **Keycloak**: Configure realm and client settings

## Keycloak Setup

Before using the system, configure Keycloak:

1. Access Keycloak admin console:
   ```
   http://localhost:30080/auth
   ```
   - Username: `admin`
   - Password: `admin`

2. Follow the main [KEYCLOAK.md](../KEYCLOAK.md) guide for detailed setup

3. Or import the realm configuration:
   - Create a new realm
   - Import `keycloak_assets/vindr-lab-realm-export.json`
   - Import authorization config `keycloak_assets/vindr-lab-backend-authz-config.json`
   - Create users

## Networking

### Ingress

k3s comes with Traefik as the default ingress controller. The ingress is configured to:
- Route all traffic on path `/` to the API gateway
- Use the `web` entrypoint (port 80)

### NodePort

A NodePort service is also created on port 30080 for easy local access.

## Troubleshooting

### Check Pod Logs
```bash
kubectl logs -n vinlab <pod-name>
kubectl logs -n vinlab <pod-name> -f  # Follow logs
```

### Describe Pod
```bash
kubectl describe pod -n vinlab <pod-name>
```

### Check Events
```bash
kubectl get events -n vinlab --sort-by='.lastTimestamp'
```

### Common Issues

1. **Pods in CrashLoopBackOff**
   - Check logs: `kubectl logs -n vinlab <pod-name>`
   - Check if dependencies are ready (ES, Redis, etc.)
   - Verify ConfigMaps are created

2. **Image Pull Errors**
   - Ensure you have created the `vindr-ecr` secret for private images:
     ```bash
     kubectl create secret docker-registry vindr-ecr \
       --docker-server=<your-registry> \
       --docker-username=<username> \
       --docker-password=<password> \
       -n vinlab
     ```

3. **502 Bad Gateway**
   - System needs time to warm up (2-3 minutes)
   - Check if all pods are running
   - Verify Keycloak is properly configured

## Undeploying

To remove VinDr Lab from your k3s cluster:

```bash
cd k3s/scripts
./02-undeploy.sh
```

This will remove all deployments but keep the namespace. To completely remove including PVCs:

```bash
kubectl delete namespace vinlab
```

## Endpoints

| Service | Internal URL | External URL (NodePort) |
|---------|-------------|-------------------------|
| Main | - | http://localhost:30080 |
| Dashboard | http://dashboard.vinlab | http://localhost:30080/dashboard |
| Backend API | http://vinlab-api.vinlab:8080 | http://localhost:30080/api |
| Orthanc | http://orthanc.vinlab:8042 | http://localhost:30080/dicomweb |
| Keycloak | http://keycloak.vinlab:8080 | http://localhost:30080/auth |
| Elasticsearch | http://es.vinlab:9200 | http://localhost:30080/elasticsearch |
| MinIO Console | http://minio.vinlab:9001 | http://localhost:30080/minio |

## Production Considerations

For production deployments, consider:

1. **Resource Limits**: Adjust memory and CPU limits in manifest files
2. **Persistent Storage**: Use a more robust storage solution (NFS, Ceph, etc.)
3. **High Availability**: Increase replica counts for critical services
4. **TLS/SSL**: Configure HTTPS with cert-manager
5. **Monitoring**: Add Prometheus and Grafana for monitoring
6. **Backup**: Implement backup strategies for PVCs
7. **Security**: Change default passwords and configure network policies

## Advanced Usage

### Manual Deployment

If you prefer to deploy services individually:

```bash
# Create namespace
kubectl apply -f manifests/00-namespace.yaml

# Create ConfigMaps
cd scripts && ./00-create-configmaps.sh

# Deploy specific service
kubectl apply -f manifests/01-elasticsearch.yaml
```

### Update a Service

```bash
# Edit the manifest file
vim manifests/08-vinlab-api.yaml

# Apply changes
kubectl apply -f manifests/08-vinlab-api.yaml

# Restart deployment
kubectl rollout restart deployment/vinlab-api-deployment -n vinlab
```

### Scale a Service

```bash
kubectl scale deployment/vinlab-api-deployment --replicas=3 -n vinlab
```

## Support

For issues and questions, please refer to the main [README.md](../README.md) or create an issue in the repository.

---

**Have fun! 🍪**
