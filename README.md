# Super Fortnight - Cloud-Native GitOps

## Overview

Production-ready GitOps repository implementing **best-in-class cloud-native practices** with **Helm + Kustomize hybrid** approach for Kubernetes deployments.

This repository demonstrates industry-leading patterns for:

- **Team Autonomy** - Service teams own their complete deployment lifecycle
- **DRY Principle** - Centralized base charts eliminate duplication
- **GitOps Excellence** - Git as single source of truth with ArgoCD automation
- **Selective Adoption** - Teams control when to adopt platform updates

## Quick Start

**New to the platform?** Start with the documentation:

📚 **[Complete Documentation](docs/README.md)**

### Choose Your Role

- **Feature Team**: [Feature Team Guide](docs/guides/feature-team-guide.md)
- **Platform Team**: [Platform Team Guide](docs/guides/platform-team-guide.md)
- **New Service**: [Adding a New Service](docs/guides/adding-new-service.md)

### Architecture Overview

```
1. Platform Chart (sf-helm-registry)
   └─> Base API Helm chart

2. Team Repositories (aggregator-service, etc.)
   └─> Application code + Kustomize deployment

3. GitOps Repository (gitops-v2)
   └─> ArgoCD application definitions
```

**Learn more**: [Three-Tier Architecture](docs/architecture/three-tier-architecture.md)

## Repository Contents

### Documentation

```
docs/
├── README.md                           # Documentation index
├── architecture/
│   ├── cloud-native-workflow.md        # Complete workflow guide
│   ├── helm-kustomize-hybrid.md        # Helm + Kustomize approach
│   └── three-tier-architecture.md      # Architecture overview
├── guides/
│   ├── platform-team-guide.md          # For platform team
│   ├── feature-team-guide.md           # For feature teams
│   ├── argocd-applications.md          # ArgoCD setup
│   └── adding-new-service.md           # Step-by-step guide
├── reference/
│   ├── helm-chart-reference.md         # Chart values reference
│   └── kustomize-patterns.md           # Common patterns
└── examples/
    ├── aggregator-implementation.md    # Real implementation
    └── helm-registry-setup.md          # Platform chart repo
```

### Helm Charts

```
helm-charts/
├── base/api/                    # Local copy (optional)
├── starters/api/                # Starter chart template
└── services/                    # Legacy service configs
```

**Note**: Services now live in team-owned repositories. See [Feature Team Guide](docs/guides/feature-team-guide.md).

## Common Workflows

### Feature Team: Deploy a Feature

```bash
# In service repository
vim src/index.ts                    # Code change
vim deploy/base/values.yaml         # Config change
git commit -m "Add feature"
git push                            # ArgoCD auto-syncs
```

### Feature Team: Adopt Platform Update

```bash
# Platform releases v0.2.0
vim deploy/base/kustomization.yaml  # version: 0.1.0 → 0.2.0
kustomize build deploy/overlays/production  # Test
git commit -m "Adopt API chart v0.2.0"
git push
```

### Platform Team: Release Chart Update

```bash
# In sf-helm-registry
vim api/templates/deployment.yaml
vim api/Chart.yaml                  # Bump version
git tag v0.2.0
git push origin main --tags
# Announce to teams
```

**Learn more**: [Cloud-Native Workflow](docs/architecture/cloud-native-workflow.md)

## Related Repositories

- **sf-helm-registry**: https://github.com/ashutosh-18k92/sf-helm-registry.git  
  Platform-maintained base API chart

- **aggregator-service**: https://github.com/ashutosh-18k92/aggregator-service.git  
  Example service implementation

- **gitops-v2**: ArgoCD application definitions

## Key Benefits

### Team Autonomy

✅ Complete ownership of service  
✅ Single repository for code + deployment  
✅ Control over platform updates  
✅ Independent release cycles

### DRY Principle

✅ Base chart eliminates duplication  
✅ Service values: 30 lines (vs 200+ before)  
✅ Shared templates across all services  
✅ Consistent patterns

### GitOps Excellence

✅ Git as single source of truth  
✅ Declarative configuration  
✅ Automated sync via ArgoCD  
✅ Easy rollback capability

### Selective Adoption

✅ Platform releases updates  
✅ Teams review and test  
✅ Teams upgrade when ready  
✅ No forced updates

## Support

- **Documentation**: [docs/README.md](docs/README.md)
- **Platform Team**: #platform-team
- **Issues**: GitHub Issues
- **Chart Repository**: https://github.com/ashutosh-18k92/sf-helm-registry

---

**For complete documentation, see [docs/README.md](docs/README.md)**
