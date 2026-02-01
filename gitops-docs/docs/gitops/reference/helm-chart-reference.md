# Helm Chart Reference

## Overview

Complete reference for the base API Helm chart in `sf-helm-registry`.

**Repository**: https://github.com/ashutosh-18k92/sf-helm-registry.git

## Chart Structure

```
api/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values.dev.yaml         # Development defaults
├── values.stage.yaml       # Staging defaults
├── values.prod.yaml        # Production defaults
├── values.schema.json      # Values validation
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── hpa.yaml
    ├── istioVirtualService.yaml
    ├── serviceAccount.yaml
    ├── _helpers.tpl
    └── tests/
        └── test-connection.yaml
```

## Values Reference

### Image Configuration

```yaml
image:
  repository: "service-name" # Container image repository
  tag: "latest" # Image tag
  pullPolicy: IfNotPresent # Pull policy
```

### Container Configuration

```yaml
containerPort: 3000 # Container port
replicaCount: 1 # Number of replicas (overridden by HPA)
```

### Environment Variables

```yaml
env:
  SERVICE_NAME: "service-name"
  LOG_LEVEL: "info"
  # Add custom environment variables
```

### Health Checks

```yaml
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
```

### Resources

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Horizontal Pod Autoscaler

```yaml
hpa:
  enabled: true
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### Istio VirtualService

```yaml
virtualService:
  enabled: true
  hosts:
    - service-name
  gateways:
    - istio-system/super-fortnight-gateway
  http:
    - match:
        - uri:
            prefix: /
      route:
        - destination:
            host: service-name-service
            port:
              number: 80
```

### Service Account

```yaml
serviceAccount:
  create: true
  annotations: {}
  name: "" # Defaults to release name
```

### Affinity Rules

```yaml
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
                  - service-name
          topologyKey: kubernetes.io/hostname
```

## Template Helpers

### microservice.name

Returns the release name.

```go-template
{{- define "microservice.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
```

### microservice.fullname

Returns `Release.Name-Chart.Name`.

```go-template
{{- define "microservice.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
```

### microservice.labels

Standard labels for all resources.

```go-template
{{- define "microservice.labels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
```

## Environment-Specific Values

### Development (values.dev.yaml)

```yaml
replicaCount: 1
env:
  LOG_LEVEL: "debug"
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
hpa:
  enabled: false
```

### Staging (values.stage.yaml)

```yaml
replicaCount: 2
env:
  LOG_LEVEL: "info"
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
```

### Production (values.prod.yaml)

```yaml
replicaCount: 3
env:
  LOG_LEVEL: "error"
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
hpa:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
```

## Usage Examples

### Minimal Service Values

```yaml
containerPort: 3000
image:
  repository: "my-service"
env:
  SERVICE_NAME: "my-service"
virtualService:
  hosts:
    - my-service
healthCheck:
  livenessProbe:
    httpGet:
      port: 3000
  readinessProbe:
    httpGet:
      port: 3000
```

### With Custom Resources

```yaml
containerPort: 8080
image:
  repository: "my-service"
env:
  SERVICE_NAME: "my-service"
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### With Custom HPA

```yaml
containerPort: 3000
image:
  repository: "my-service"
hpa:
  enabled: true
  minReplicas: 5
  maxReplicas: 50
  targetCPUUtilizationPercentage: 70
```

## Related Documentation

- [Platform Team Guide](../guides/platform-team-guide.md)
- [Feature Team Guide](../guides/feature-team-guide.md)
- [Helm Registry Setup](../examples/helm-registry-setup.md)
