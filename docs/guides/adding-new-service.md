# Adding a New Service

## Overview

This guide walks you through adding a new microservice to the Super Fortnight platform using the Helm + Kustomize hybrid approach.

## Prerequisites

- Access to create GitHub repositories
- `kustomize` installed locally
- `kubectl` configured for your cluster
- ArgoCD CLI installed (optional)

## Step-by-Step Guide

### Step 1: Create Team Repository

Create a new GitHub repository for your service:

```bash
# Create repository on GitHub
# Example: https://github.com/your-org/new-service.git

# Clone locally
git clone https://github.com/your-org/new-service.git
cd new-service
```

### Step 2: Set Up Application Code

Create your application structure:

```bash
# Create directories
mkdir -p src

# Initialize package.json (for Node.js services)
npm init -y

# Create basic application
cat > src/index.ts <<EOF
import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/ready', (req, res) => {
  res.json({ status: 'ready' });
});

app.listen(PORT, () => {
  console.log(\`Service listening on port \${PORT}\`);
});
EOF

# Create Dockerfile
cat > Dockerfile <<EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
CMD ["node", "src/index.ts"]
EOF
```

### Step 3: Set Up Deployment Structure

Create the deployment configuration:

```bash
# Create directory structure
mkdir -p deploy/base
mkdir -p deploy/overlays/dev
mkdir -p deploy/overlays/production/patches
```

### Step 4: Create Base Configuration

**File**: `deploy/base/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: api
    repo: https://github.com/ashutosh-18k92/sf-helm-registry.git
    releaseName: new-service
    namespace: super-fortnight
    valuesFile: values.yaml
    version: 0.1.0 # Use latest stable version
    includeCRDs: false
```

**File**: `deploy/base/values.yaml`

```yaml
# Service-specific configuration
containerPort: 3000

image:
  repository: "new-service"
  tag: "latest"

env:
  SERVICE_NAME: "new-service"
  LOG_LEVEL: "info"

virtualService:
  enabled: true
  hosts:
    - new-service
  gateways:
    - istio-system/super-fortnight-gateway

healthCheck:
  livenessProbe:
    httpGet:
      path: /health
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /ready
      port: 3000
    initialDelaySeconds: 10
    periodSeconds: 5

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Step 5: Create Development Overlay

**File**: `deploy/overlays/dev/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namespace: super-fortnight-dev

configMapGenerator:
  - name: service-config
    literals:
      - LOG_LEVEL=debug
      - ENABLE_DEBUG=true
```

### Step 6: Create Production Overlay

**File**: `deploy/overlays/production/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namespace: super-fortnight

patchesStrategicMerge:
  - patches/deployment-affinity.yaml
  - patches/hpa-scaling.yaml
  - patches/production-resources.yaml

configMapGenerator:
  - name: service-config
    literals:
      - LOG_LEVEL=error
      - ENABLE_DEBUG=false
```

**File**: `deploy/overlays/production/patches/deployment-affinity.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-service-api-v1
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                        - new-service-api-v1
                topologyKey: kubernetes.io/hostname
            - weight: 50
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                        - new-service-api-v1
                topologyKey: topology.kubernetes.io/zone
```

**File**: `deploy/overlays/production/patches/hpa-scaling.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: new-service-api-v1-hpa
spec:
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

**File**: `deploy/overlays/production/patches/production-resources.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-service-api-v1
spec:
  template:
    spec:
      containers:
        - name: api
          resources:
            requests:
              memory: "256Mi"
              cpu: "200m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

### Step 7: Test Locally

```bash
# Test kustomize build
kustomize build deploy/overlays/production

# Validate manifests
kustomize build deploy/overlays/production | kubectl apply --dry-run=client -f -

# Save for review
kustomize build deploy/overlays/production > /tmp/new-service-prod.yaml
less /tmp/new-service-prod.yaml
```

### Step 8: Commit and Push

```bash
# Add all files
git add .

# Commit
git commit -m "Initial service setup with Helm + Kustomize"

# Push to GitHub
git push origin main
```

### Step 9: Create ArgoCD Application (Production)

In the `gitops-v2` (or `gitops-v3`) repository:

```bash
cd /path/to/gitops-v2/services

cat > new-service.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: new-service
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/new-service.git
    targetRevision: main
    path: deploy/overlays/production
    kustomize:
      version: v5.0.0
  destination:
    server: https://kubernetes.default.svc
    namespace: super-fortnight
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

### Step 10: Create ArgoCD Application (Development)

```bash
cat > new-service-dev.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: new-service-dev
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/new-service.git
    targetRevision: main
    path: deploy/overlays/dev
    kustomize:
      version: v5.0.0
  destination:
    server: https://kubernetes.default.svc
    namespace: super-fortnight-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

### Step 11: Apply ArgoCD Applications

```bash
# Apply to cluster
kubectl apply -f new-service.yaml
kubectl apply -f new-service-dev.yaml

# Verify
kubectl get applications -n argocd | grep new-service
```

### Step 12: Verify Deployment

```bash
# Check ArgoCD sync status
argocd app get new-service
argocd app get new-service-dev

# Check pods
kubectl get pods -n super-fortnight -l app.kubernetes.io/name=new-service-api-v1
kubectl get pods -n super-fortnight-dev -l app.kubernetes.io/name=new-service-api-v1

# Check service
kubectl get svc -n super-fortnight -l app.kubernetes.io/name=new-service-api-v1

# Check logs
kubectl logs -n super-fortnight -l app.kubernetes.io/name=new-service-api-v1 --tail=50
```

## Directory Structure Summary

Your final repository structure:

```
new-service/
├── src/
│   └── index.ts
├── deploy/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yaml
│       └── production/
│           ├── kustomization.yaml
│           └── patches/
│               ├── deployment-affinity.yaml
│               ├── hpa-scaling.yaml
│               └── production-resources.yaml
├── package.json
├── Dockerfile
└── README.md
```

## Checklist

Before considering your service complete:

- [ ] Application code committed and pushed
- [ ] Deployment structure created (`deploy/base` and `deploy/overlays`)
- [ ] Base values configured (`deploy/base/values.yaml`)
- [ ] Development overlay created
- [ ] Production overlay with patches created
- [ ] Tested locally with `kustomize build`
- [ ] ArgoCD applications created (dev and production)
- [ ] Applications applied to cluster
- [ ] Verified sync status in ArgoCD
- [ ] Verified pods are running
- [ ] Verified service is accessible
- [ ] Documentation updated (README.md)

## Troubleshooting

### Kustomize Build Fails

```bash
# Check syntax
kustomize build deploy/overlays/production

# Verify chart version exists
git ls-remote --tags https://github.com/ashutosh-18k92/sf-helm-registry.git
```

### ArgoCD Sync Fails

```bash
# Check application status
argocd app get new-service

# View detailed errors
kubectl describe application new-service -n argocd

# Manual sync
argocd app sync new-service --force
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n super-fortnight -l app.kubernetes.io/name=new-service-api-v1

# Check events
kubectl get events -n super-fortnight --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n super-fortnight -l app.kubernetes.io/name=new-service-api-v1
```

## Next Steps

After your service is deployed:

1. **Monitor**: Set up monitoring and alerting
2. **Scale**: Adjust HPA settings based on load
3. **Optimize**: Fine-tune resource requests/limits
4. **Document**: Update README with service-specific information
5. **Iterate**: Continue development with confidence!

## Related Documentation

- [Feature Team Guide](feature-team-guide.md)
- [Platform Team Guide](platform-team-guide.md)
- [ArgoCD Applications](argocd-applications.md)
- [Three-Tier Architecture](../architecture/three-tier-architecture.md)
- [Cloud-Native Workflow](../architecture/cloud-native-workflow.md)
