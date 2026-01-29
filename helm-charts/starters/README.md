# Helm Charts

Helm charts will simply our release management and service versioning.

## Creating starters

```bash
helm create microservice
```

Then adjust the values and templates as needed.

The charts can be refenced in two ways either throught absolute path or putting in the helm shared starter folder.

### Preview Templates

```bash
mkdir -p path/to/rendered
helm template my-release path/to/chart --output-dir path/to/rendered
```

### Lint

```
cd /path/to/chart
helm lint .
```

### Update dependency

**local subchart dependency**

```
dependencies:
  - name: mysubchart
    version: "0.1.0" # Must match the version in mysubchart/Chart.yaml
    repository: "file://./charts/mysubchart"
```

```
cd /path/to/chart
helm dependency update
```

### helm package

```
helm package -u path/to/chart

# -u update dependency
```

### using chart to create services

```
helm create my-new-service --starter=<absolute-chart-path>
```

This creates a my-new-service chart identical to the starter chart.

### Create your release

```
helm install my-service-release path/to/my-new-service

#with values
helm install my-service-release path/to/my-new-service --values values.{env}.yaml

#with --set
helm install my-service-release path/to/my-new-service --set version=v2 --set image.repository=service --set image.tag=latest
```

## Todos

- [] We should have a method to check the release numbers, say v1.0, then we build a docker image based on this and our chart also refers the same version. To get the charts and docker images in sync.

```

```
