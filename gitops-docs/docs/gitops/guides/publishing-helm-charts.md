# Publishing Helm Charts with GitHub Actions

This guide explains how to set up automated Helm chart publishing using GitHub Actions and GitHub Pages.

## Overview

We use two GitHub Actions workflows:

1. **chart-releaser-action**: Automatically packages and publishes charts to GitHub Pages
2. **chart-testing-action**: Lints and tests charts on pull requests

## Setup Steps

### Step 1: Create gh-pages Branch

```bash
# In your service repository
cd /path/to/your-service

# Create gh-pages branch from main
git checkout -b gh-pages

# Clean up the branch (optional)
echo "# Helm Charts" > README.md
git add README.md
git commit -m "Initialize gh-pages branch"
git push origin gh-pages

# Switch back to main
git checkout main
```

### Step 2: Configure GitHub Pages

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Under **Build and deployment**:
   - **Source**: Select "Deploy from a branch"
   - **Branch**: Select `gh-pages` and `/ (root)`
4. Click **Save**

Your charts will be available at: `https://<username>.github.io/<repo-name>/`

### Step 3: Create Workflows Directory

```bash
# In your service repository
mkdir -p .github/workflows
```

### Step 4: Add Chart Release Workflow

Create `.github/workflows/release-helm-chart.yml`:

```yaml
name: Release Charts

on:
  push:
    branches:
      - main

jobs:
  release:
    permissions:
      contents: write
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.name "$GITHUB_ACTOR"
          git config user.email "$GITHUB_ACTOR@users.noreply.github.com"

      - name: Run chart-releaser
        uses: helm/chart-releaser-action@v1.6.0
        env:
          CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
```

**What this does**:

- Triggers on every push to `main`
- Automatically packages charts in `charts/` directory
- Creates GitHub releases for new chart versions
- Publishes to `gh-pages` branch
- Updates Helm repository index

### Step 5: Add Chart Testing Workflow

Create `.github/workflows/test-lint-helm-chart.yml`:

```yaml
name: Lint and Test Charts

on: pull_request

permissions: {}

jobs:
  lint-test:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Helm
        uses: azure/setup-helm@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.x"
          check-latest: true

      - name: Set up chart-testing
        uses: helm/chart-testing-action@v2.8.0

      - name: Run chart-testing (list-changed)
        id: list-changed
        run: |
          changed=$(ct list-changed --target-branch ${{ github.event.repository.default_branch }})
          if [[ -n "$changed" ]]; then
            echo "changed=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Run chart-testing (lint)
        if: steps.list-changed.outputs.changed == 'true'
        run: ct lint --target-branch ${{ github.event.repository.default_branch }}

      - name: Create kind cluster
        if: steps.list-changed.outputs.changed == 'true'
        uses: helm/kind-action@v1.12.0

      - name: Run chart-testing (install)
        if: steps.list-changed.outputs.changed == 'true'
        run: ct install --target-branch ${{ github.event.repository.default_branch }}
```

**What this does**:

- Triggers on pull requests
- Lints changed charts
- Tests chart installation in a kind cluster
- Ensures chart quality before merge

### Step 6: Create Charts Directory

```bash
# Your service chart must be inside the charts directory
mkdir -p charts

# Create your service chart
helm create charts/your-service --starter=sf-charts/api

# Or move existing chart
mv your-service charts/
```

**Important**: The `chart-releaser-action` expects charts to be in the `charts/` directory.

### Step 7: Commit and Push

```bash
# Add workflows
git add .github/workflows/

# Add your chart
git add charts/

# Commit
git commit -m "Add Helm chart and GitHub Actions workflows"

# Push to main
git push origin main
```

### Step 8: Verify Release

1. Go to **Actions** tab in GitHub
2. Watch the "Release Charts" workflow run
3. Check **Releases** tab for new chart release
4. Verify chart is available:
   ```bash
   helm repo add your-service https://<username>.github.io/<repo-name>
   helm search repo your-service
   ```

## Chart Versioning

The `chart-releaser-action` automatically creates releases when you:

1. **Bump chart version** in `charts/your-service/Chart.yaml`:

   ```yaml
   version: 0.1.1 # Increment this
   ```

2. **Commit and push** to main:

   ```bash
   git add charts/your-service/Chart.yaml
   git commit -m "Bump chart version to 0.1.1"
   git push origin main
   ```

3. **Workflow runs automatically**:
   - Detects version change
   - Packages chart
   - Creates GitHub release
   - Updates gh-pages

## Using Your Published Chart

### In Kustomize Overlays

```yaml
# deploy/overlays/development/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: your-service
    repo: https://<username>.github.io/<repo-name>
    releaseName: your-service
    namespace: super-fortnight-dev
    valuesFile: values.yaml
    version: 0.1.0
    includeCRDs: false
```

### Direct Helm Install

```bash
# Add repository
helm repo add your-service https://<username>.github.io/<repo-name>

# Update repositories
helm repo update

# Install chart
helm install my-release your-service/your-service
```

## Troubleshooting

### Workflow Fails: "No charts to release"

**Cause**: No version changes detected in `charts/` directory.

**Solution**: Bump the `version` in `Chart.yaml` before pushing.

### Chart Not Found After Release

**Cause**: GitHub Pages not configured correctly.

**Solution**:

1. Check Settings → Pages
2. Ensure source is `gh-pages` branch
3. Wait a few minutes for GitHub Pages to deploy

### Lint Failures

**Cause**: Chart doesn't pass `helm lint` checks.

**Solution**:

```bash
# Test locally before pushing
helm lint charts/your-service

# Fix issues and commit
```

## Best Practices

1. **Always bump version**: Increment `version` in `Chart.yaml` for every change
2. **Test locally first**: Run `helm lint` and `helm template` before pushing
3. **Use semantic versioning**: Follow semver (MAJOR.MINOR.PATCH)
4. **Document changes**: Update chart README with each version
5. **Review PR checks**: Ensure lint and test workflows pass before merging

## References

- [Helm Chart Releaser Action](https://github.com/helm/chart-releaser-action)
- [Helm Chart Testing Action](https://github.com/helm/chart-testing-action)
- [Helm Chart Releaser Documentation](https://helm.sh/docs/howto/chart_releaser_action/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
