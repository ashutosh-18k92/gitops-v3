# Helm + Kustomize Hybrid Approach

## Overview

This document describes the Helm + Kustomize hybrid workflow for managing service charts in a multi-team environment.

## Why This Approach?

In production environments with multiple teams:

- **Team Autonomy**: Each team owns their service completely
- **Selective Updates**: Teams choose when to adopt base chart changes
- **No Forced Sync**: No central script forcing updates
- **Version Control**: Each service can use different base chart versions
- **Custom Patches**: Teams can override any behavior without modifying base templates

## Architecture

```
Base Chart Repository:
https://github.com/ashutosh-18k92/sf-helm-registry.git
  └── api/                          # Reference chart (platform team maintains)
      ├── templates/
      ├── values.yaml
      └── Chart.yaml

Service Repository (gitops-v3):
└── services/
    └── aggregator/                 # Team-owned service
        ├── base/
        │   ├── kustomization.yaml  # References GitHub chart
        │   └── values.yaml         # Service-specific values
        └── overlays/
            ├── dev/
            │   └── kustomization.yaml
            └── production/
                ├── kustomization.yaml
                └── patches/
                    ├── deployment-affinity.yaml
                    └── hpa-scaling.yaml
```

## How It Works

### 1. Base Chart (Platform Team)

Platform team maintains the reference API chart in a separate GitHub repository:
**https://github.com/ashutosh-18k92/sf-helm-registry.git**

### 2. Service Base (Team-Owned)

Each feature team creates a `base/kustomization.yaml` that references the GitHub chart:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: api
    repo: https://github.com/ashutosh-18k92/sf-helm-registry.git
    releaseName: aggregator
    namespace: super-fortnight
    valuesFile: values.yaml
    version: 0.1.0 # Team controls version!
    includeCRDs: false
```

### 3. Environment Overlays (Team-Owned)

Teams create environment-specific overlays with patches:

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patches/deployment-affinity.yaml
  - patches/hpa-scaling.yaml

configMapGenerator:
  - name: service-config
    literals:
      - LOG_LEVEL=error
```

## Team Workflows

### Adopting Base Chart Updates

```bash
# Platform releases new version
# Team reviews and decides to upgrade

cd services/aggregator/base
vim kustomization.yaml
# Change version: 0.1.0 → 0.2.0

# Test locally
kustomize build ../overlays/production

# Commit when ready
git commit -m "Upgrade to API chart v0.2.0"
```

### Creating Custom Patches

```bash
cd services/aggregator/overlays/production

# Create patch file
cat > patches/custom-feature.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aggregator-api-v1
spec:
  template:
    spec:
      containers:
        - name: api
          env:
            - name: CUSTOM_FEATURE
              value: "enabled"
EOF

# Add to kustomization
vim kustomization.yaml
# Add to patchesStrategicMerge
```

### Staying on Older Version

```bash
# Team decides not to upgrade yet
# No action needed - version stays at 0.1.0
# Team can upgrade when ready
```

## ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aggregator-prod
spec:
  source:
    repoURL: https://github.com/your-org/gitops-v3
    targetRevision: main
    path: services/aggregator/overlays/production
    kustomize:
      version: v5.0.0
  destination:
    server: https://kubernetes.default.svc
    namespace: super-fortnight
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Migration Guide

See the aggregator service for a complete example of the migration from pure Helm to Helm + Kustomize hybrid.

### Migration Steps

1. **Create directory structure**:

   ```bash
   mkdir -p services/{service}/base
   mkdir -p services/{service}/overlays/{dev,production}
   ```

2. **Move values to base**:

   ```bash
   mv services/{service}/values.yaml services/{service}/base/
   ```

3. **Create base kustomization**:
   Reference the base API chart with service-specific values

4. **Create environment overlays**:
   Add patches for environment-specific configuration

5. **Update ArgoCD application**:
   Change from Helm to Kustomize source

6. **Test and deploy**:
   ```bash
   kustomize build services/{service}/overlays/production
   ```

## Best Practices

### ✅ DO

- Pin specific base chart versions
- Use strategic merge for simple changes
- Document patches with comments
- Test with `kustomize build` before committing
- Keep patches minimal and focused

### ❌ DON'T

- Don't use `latest` version
- Don't create massive patches (indicates base chart issue)
- Don't duplicate logic across overlays
- Don't patch templates directly

## Comparison with Sync Script

| Aspect             | Sync Script       | Kustomize Hybrid |
| ------------------ | ----------------- | ---------------- |
| Team Autonomy      | ❌ Forced updates | ✅ Teams choose  |
| Selective Adoption | ❌ All or nothing | ✅ Pick features |
| Custom Patches     | ❌ Overwritten    | ✅ Preserved     |
| Version Control    | ❌ Single version | ✅ Per-service   |
| Complexity         | ✅ Simple         | ⚠️ Moderate      |

## Resources

- [Kustomize Documentation](https://kustomize.io/)
- [ArgoCD Kustomize Support](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/)
- [Helm Chart Rendering in Kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md)
