#!/usr/bin/env bash

set -euo pipefail

helm lint microservice
mkdir -p render-dev render-stage render-prod render
helm template microservice --values microservice/values.yaml --output-dir render
helm template microservice --values microservice/values.dev.yaml --output-dir render-dev
helm template microservice --values microservice/values.stage.yaml --output-dir render-stage
helm template microservice --values microservice/values.prod.yaml --output-dir render-prod

helm package microservice --version 0.1.0 --app-version 0.1.0 --destination charts
cp charts/microservice*.tgz $HELM_STARTERS_HOME
