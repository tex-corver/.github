# Build and Push Docker Image Workflow Guide

This guide will help you use the predefined 'Build and Push Docker Image' GitHub Actions workflow for your projects.

## Overview

The workflow is a reusable GitHub Action that automates the complete CI/CD pipeline for Docker-based applications. It handles:

- 🧪 Running tests
- 🐳 Building and pushing Docker images to our registry
- 🚀 Deploying to development environment (on master/main, tags, or releases)
- ✅ Verifying deployment
- 📝 Creating pull requests for `master`

## Workflow Behavior

The workflow runs in stages based on the trigger event:

### Stage 1: Test & Build (Always)

- **Triggers**: Any push event, pull request, or workflow dispatch
- **Actions**:
  - Runs tests (via `test-command`)
  - Builds Docker image
  - Pushes image to registry

### Stage 2: Deploy (Conditional)

- **Triggers**: Only when:
  - Push to `master` or `main` branch
  - Push a tag (e.g., `v1.0.0`, `release-1.2.3`)
  - Create a GitHub Release
- **Actions**:
  - Deploys to development/staging environment
  - Creates Kubernetes manifests
  - Syncs with ArgoCD
  - Verifies deployment health

### Stage 3: Create PR (Conditional)

- **Triggers**: Only when:
  - Pushed to a feature branch (not master/main)
  - `create-pr` input is `true` (default)
- **Actions**:
  - Creates/updates PR to master
  - Includes deployment link
  - Requests reviews

### Workflow Decision Tree

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Trigger Event Received                      │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  Run Tests & Build     │
                    │  Docker Image          │
                    └────────────┬───────────┘
                                 │
                    ┌────────────▼───────────┐
                    │ Check Trigger Type     │
                    └────────────┬───────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
        ▼                        ▼                        ▼
┌───────────────┐        ┌──────────────┐        ┌──────────────┐
│ Push to       │        │ Push Tag OR  │        │ Push to      │
│ Feature Branch│        │ Create       │        │ PR to Master │
│               │        │ Release      │        │              │
└───────┬───────┘        └──────┬───────┘        └──────┬───────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐        ┌──────────────┐        ┌──────────────┐
│ Create/Update │        │ Deploy to    │        │ Only Test &  │
│ Pull Request  │        │ Environment  │        │ Build        │
│ to Master     │        │              │        │              │
└───────────────┘        └──────┬───────┘        └──────────────┘
                                │
                                ▼
                        ┌──────────────┐
                        │ Verify       │
                        │ Deployment   │
                        └──────────────┘
```

## How to Configure Workflow Triggers

The reusable workflow can be triggered in different ways. Configure the `on:` section in your workflow file to control when the workflow runs.

### Trigger on Push to Branches

**Test & Build on every push**:

```yaml
name: Deploy Application

on:
  push:
    branches: [dev, feature/*, master, main]

jobs:
  deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: "my-app"
```

- Pushes to `master`/`main` → Test + Build + **Deploy**
- Pushes to other branches → Test + Build + Create PR

### Trigger on Pull Requests

**Test & Build on every PR (no deployment)**:

```yaml
name: Test Pull Request

on:
  pull_request:
    branches: [master, main]
    types: [opened, synchronize, reopened]

jobs:
  test-and-build:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: "my-app"
      create-pr: false # Don't create another PR
```

This runs tests and builds the Docker image for every PR, but **does not deploy** since it's not a push to master/main or a tag.

### Trigger on Tags

**Deploy when pushing version tags**:

```yaml
name: Deploy on Tag

on:
  push:
    tags:
      - "v*" # Matches v1.0.0, v2.1.3, etc.
      - "release-*" # Matches release-1.0, release-2024.11.10

jobs:
  deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: "my-app"
      tag: ${{ github.ref_name }} # Use the tag name as Docker image tag
```

**Common tag patterns**:

- `v*` - Semantic versions (v1.0.0, v2.1.3)
- `v*.*.*` - Strict semantic versions only
- `release-*` - Custom release format
- `*` - Any tag (use with caution)

### Trigger on GitHub Releases

**Deploy when creating a GitHub Release**:

```yaml
name: Deploy on Release

on:
  release:
    types: [published] # Or: created, released, prereleased

jobs:
  deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: "my-app"
      tag: ${{ github.event.release.tag_name }} # Use release tag
```

**Release event types**:

- `published` - Release is published (not draft)
- `created` - Release is created (including drafts)
- `released` - Release is published (deprecated, use `published`)
- `prereleased` - Pre-release is published

### Complete Configuration (All Triggers)

**Comprehensive workflow that handles all scenarios**:

```yaml
name: CI/CD Pipeline

on:
  # Run on push to any branch
  push:
    branches:
      - "**" # All branches
    tags:
      - "v*" # Version tags
      - "release-*" # Release tags

  # Run on pull requests to main branches
  pull_request:
    branches: [master, main]
    types: [opened, synchronize, reopened]

  # Run on GitHub releases
  release:
    types: [published]

  # Allow manual trigger
  workflow_dispatch:
    inputs:
      deploy-env:
        description: "Deployment environment"
        required: false
        default: "dev"

jobs:
  deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: "my-app"
      tag: ${{ github.ref_name }}
```

**What happens with this configuration**:

| Event                   | Branches/Tags      | Behavior                                      |
| ----------------------- | ------------------ | --------------------------------------------- |
| Push to `feature/*`     | Any feature branch | Test + Build + Create PR                      |
| Push to `master`/`main` | Main branches      | Test + Build + **Deploy**                     |
| Push tag `v1.0.0`       | Version tag        | Test + Build + **Deploy**                     |
| Create Release          | Any                | Test + Build + **Deploy**                     |
| Pull Request            | To master/main     | Test + Build (no deploy, no PR)               |
| Manual trigger          | -                  | Test + Build + Deploy (if on master/main/tag) |

### Recommended Configurations

#### 1. Simple Development Workflow

```yaml
on:
  push:
    branches: [master, main, dev]
  workflow_dispatch:
```

- Good for: Small teams, simple projects
- Deploys on: Push to master, main, or dev

#### 2. Feature Branch + Production Releases

```yaml
on:
  push:
    branches: [master, main, "feature/**"]
    tags: ["v*"]
  pull_request:
    branches: [master, main]
```

- Good for: Medium-sized projects with code review
- Deploys on: Push to master/main, version tags
- Creates PRs: From feature branches

#### 3. Full CI/CD with Releases

```yaml
on:
  push:
    branches: ["**"]
    tags: ["v*", "v*.*.*-rc*"]
  pull_request:
    branches: [master, main, develop]
  release:
    types: [published, prereleased]
  workflow_dispatch:
```

- Good for: Large projects, public releases
- Deploys on: Master/main, tags, releases
- Tests on: All PRs and pushes

## Quick Start

### 1. Basic Usage

Create a workflow file in your repository (e.g., `.github/workflows/deploy.yaml`):

```yaml
name: Deploy Application

on:
  push:
    branches: [dev, feature/*, master, main]
    tags: ["v*", "release-*"]
  release:
    types: [published]
  workflow_dispatch:

jobs:
  deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: "my-app"
      # Add other parameters as needed
```

**Note**: The workflow automatically handles different scenarios:

- Feature branches: Tests + Build + Create PR
- Master/Main: Tests + Build + Deploy
- Tags: Tests + Build + Deploy
- Releases: Tests + Build + Deploy

### 2. Example with Custom Configuration

```yaml
name: Deploy My FastAPI App

on:
  push:
    branches: [dev]
  workflow_dispatch:

jobs:
  deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      org-name: "jannic-ai"
      project-name: "api-service"
      docker-build-file: "src/apps/api/Dockerfile"
      docker-build-context: "."
      port: 8080
      ingress: true
      fastapi-root-path: "/api/v1"
      config-path: "config/production.yaml"
```

## Input Parameters

### Required Parameters

| Parameter      | Type   | Description                            | Example                       |
| -------------- | ------ | -------------------------------------- | ----------------------------- |
| `project-name` | string | Unique identifier for your application | `"api-service"`, `"frontend"` |

### Optional Parameters

#### Basic Configuration

| Parameter      | Type   | Default          | Description                                                  |
| -------------- | ------ | ---------------- | ------------------------------------------------------------ |
| `org-name`     | string | Repository owner | Organization/team name (e.g., `"tex-corver"`, `"jannic-ai"`) |
| `tag`          | string | `"dev"`          | Docker image tag/version (e.g., `"v1.0.0"`, `"prod"`)        |
| `test-command` | string | `"make test"`    | Command to run tests (e.g., `"npm test"`, `"pytest"`)        |

#### Docker Configuration

| Parameter              | Type   | Default        | Description                                             |
| ---------------------- | ------ | -------------- | ------------------------------------------------------- |
| `docker-build-file`    | string | `"Dockerfile"` | Path to Dockerfile (e.g., `"docker/prod.Dockerfile"`)   |
| `docker-build-context` | string | `"."`          | Docker build context directory (e.g., `"src/apps/api"`) |

#### Network Configuration

| Parameter        | Type    | Default | Description                                                |
| ---------------- | ------- | ------- | ---------------------------------------------------------- |
| `port`           | number  | `8000`  | Application port inside container (e.g., `3000`, `8080`)   |
| `ingress`        | boolean | `true`  | Enable HTTPS access via internet                           |
| `ingress-domain` | string  | `""`    | Domain prefix for public URL (e.g., `"api"`, `"app.team"`) |
| `root-path`      | string  | `""`    | URL path prefix (e.g., `"/api/v1"`, `"/payments"`)         |

#### Configuration & Secrets

| Parameter           | Type   | Default | Description                                                |
| ------------------- | ------ | ------- | ---------------------------------------------------------- |
| `config-path`       | string | `""`    | Path to config file mounted to container                   |
| `config-secret`     | string | `""`    | Path to encrypted config file (e.g., `".config.enc.yaml"`) |
| `env-file`          | string | `""`    | Environment variables file in KEY=VALUE format             |
| `env-secret`        | string | `""`    | Path to encrypted env file                                 |
| `extra-secret-name` | string | `""`    | Name of extra Kubernetes secret                            |
| `extra-secret-file` | string | `""`    | Path to extra secret file                                  |
| `extra-secret-path` | string | `""`    | Mount path for extra secret in container                   |

#### Health Check Configuration

| Parameter         | Type   | Default | Description                                                          |
| ----------------- | ------ | ------- | -------------------------------------------------------------------- |
| `liveness-path`   | string | `""`    | HTTP path for liveness probe (e.g., `"/healthz"`, `"/ping"`)         |
| `readiness-path`  | string | `""`    | HTTP path for readiness probe (e.g., `"/ready"`, `"/health"`)        |

#### Monitoring Configuration

| Parameter             | Type    | Default | Description                                  |
| --------------------- | ------- | ------- | -------------------------------------------- |
| `service-monitor`     | boolean | `false` | Enable Prometheus ServiceMonitor for metrics |
| `prometheus-rule`     | boolean | `false` | Create Prometheus alerting rules             |
| `alertmanager-config` | boolean | `false` | Create Alertmanager configuration            |

#### Pull Request Behavior

| Parameter   | Type    | Default | Description                                    |
| ----------- | ------- | ------- | ---------------------------------------------- |
| `create-pr` | boolean | `true`  | Auto-create PR to master from feature branches |

## Example

### TexCorver Landing Page (`tex-corver/tex-corver`)

```yaml
jobs:
  call-common-workflow:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: tex-corver
      tag: v1
      port: 3000
      ingress: true
```

### FastAPI Application (`tex-corver/metis`)

```yaml
jobs:
  call-common-workflow:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      project-name: tex-corver
      tag: v1
      port: 8000
      ingress: true
```

### Microservice with Custom Dockerfile (`tex-corver/metis`)

```yaml
jobs:
  call-common-workflow:
    strategy:
      matrix:
        service: [schedule-manager, dataset-manager, execution-manager, worker]
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      org-name: tex-corver
      project-name: metis-${{ matrix.service }}
      tag: v1
      docker-build-file: src/apps/${{ matrix.service }}/Dockerfile
      docker-build-context: .
      port: 8000
      ingress: true
      ingress-subdomain: metis
      root-path: /${{ matrix.service }}
      config-path: src/apps/${{ matrix.service }}/.configs.sample
```

> **_NOTE:_** Others parrarel jobs will be skipped if one of them fails.

## Build Cache Optimization

### How It Works

The workflow automatically uses **Docker registry cache** to speed up builds:

```yaml
cache-from: type=registry,ref=${{ env.REGISTRY }}/cache/cache
cache-to: type=registry,ref=${{ env.REGISTRY }}/cache/cache,mode=max
```

**Benefits**:

- ⚡ **Faster builds**: Reuses layers from previous builds (can be 5-10x faster)
- 💰 **Cost savings**: Reduces build time and runner usage
- 🔄 **Shared cache**: All team members and branches benefit from the same cache

### How to Maximize Cache Efficiency

The cache effectiveness depends on your Dockerfile structure:

| Dockerfile Quality                     | First Build | Subsequent Builds | Code Change Build |
| -------------------------------------- | ----------- | ----------------- | ----------------- |
| ❌ Poor (code before deps)             | 5 min       | 5 min             | 5 min             |
| ⚠️ OK (deps before code)               | 5 min       | 30 sec            | 2 min             |
| ✅ Excellent (multi-stage + optimized) | 5 min       | 10 sec            | 30 sec            |

#### Example: Cache Hit Rate

```bash
# First build (no cache)
[Build] Step 1/5 : FROM python:3.12-slim          # 15s (download)
[Build] Step 2/5 : COPY requirements.txt          # 0.1s
[Build] Step 3/5 : RUN pip install -r ...         # 120s (install)
[Build] Step 4/5 : COPY . .                       # 0.5s
[Build] Step 5/5 : CMD ["python", "app.py"]       # 0.1s
Total: ~135s

# Second build (with cache, no changes)
[Cache] Step 1/5 : FROM python:3.12-slim          # CACHED
[Cache] Step 2/5 : COPY requirements.txt          # CACHED
[Cache] Step 3/5 : RUN pip install -r ...         # CACHED
[Cache] Step 4/5 : COPY . .                       # CACHED
[Cache] Step 5/5 : CMD ["python", "app.py"]       # CACHED
Total: ~5s

# Third build (code changes, good Dockerfile)
[Cache] Step 1/5 : FROM python:3.12-slim          # CACHED
[Cache] Step 2/5 : COPY requirements.txt          # CACHED
[Cache] Step 3/5 : RUN pip install -r ...         # CACHED ✅
[Build] Step 4/5 : COPY . .                       # 0.5s
[Cache] Step 5/5 : CMD ["python", "app.py"]       # CACHED
Total: ~6s
```

### Monitoring Cache Performance

Check your GitHub Actions logs for cache usage:

```text
✅ Good cache performance:
#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 486B done
#2 [internal] load .dockerignore
#2 transferring context: 2B done
#3 [internal] load metadata for docker.io/library/python:3.12-slim
#3 DONE 0.5s
#4 importing cache manifest from registry.../cache/cache
#4 DONE 1.2s
...
#8 [3/5] RUN pip install -r requirements.txt
#8 CACHED  ← This is what you want to see!
```

## Deployment URL

If you specify `ingress: true`, the application will be accessible at:

```text
https://{org-name}.urieljsc.com{root-path}
```

Example: `https://my-team.urieljsc.com/api/v1`

## Prerequisites

### 1. Dockerfile Requirements

- Your Dockerfile should be in the specified location
- Application should run on the configured port

### 2. Configuration File

- Provide a configuration file (default: README.md)

## Deployment Triggers

The workflow deploys your application to the development environment in the following scenarios:

### 1. Push to Master/Main Branch

```bash
git checkout master
git merge feature/my-feature
git push origin master
```

This is the standard deployment path after code review and PR approval.

### 2. Push a Tag

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# Or create an annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Push all tags
git push --tags
```

**Use cases for tags**:

- Versioned releases (e.g., `v1.0.0`, `v2.1.3`)
- Release candidates (e.g., `v1.0.0-rc1`)
- Build numbers (e.g., `release-2024.11.10`)

**Best practices**:

- Use semantic versioning: `vMAJOR.MINOR.PATCH`
- Add meaningful tag messages for annotated tags
- Tags should point to tested, stable commits

### 3. Create a GitHub Release

**Via GitHub UI**:

1. Go to your repository on GitHub
2. Click "Releases" → "Create a new release"
3. Choose a tag (or create new)
4. Add release notes
5. Click "Publish release"

**Via GitHub CLI**:

```bash
gh release create v1.0.0 --title "Version 1.0.0" --notes "Release notes here"
```

**Use cases**:

- Public releases with changelogs
- Binary/asset distribution
- Production deployments

### Why Multiple Trigger Options?

- **Master/Main push**: Continuous deployment for ongoing development
- **Tags**: Version-controlled deployments, rollback capability
- **Releases**: Formal releases with documentation and assets

## Best Practices

### 1. Branch Strategy

- Use `dev` or feature branches for development
- Create feature branches for new features
- Merge to master after code review
- Workflow auto-creates PRs to master from feature branches

### 2. Writing Efficient Dockerfiles

**IMPORTANT**: The workflow uses Docker build cache to speed up builds. Write your Dockerfile to maximize cache efficiency.

#### Key Principles

**Order layers by change frequency** (least → most frequent):

```dockerfile
# ❌ BAD: Application code changes invalidate dependency cache
FROM python:3.12-slim
WORKDIR /app
COPY . .                          # Copies everything, including code
RUN pip install -r requirements.txt  # Re-installs deps on every code change
CMD ["python", "app.py"]

# ✅ GOOD: Dependencies cached separately from code
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .           # Only copy dependency file first
RUN pip install -r requirements.txt  # Cached unless requirements.txt changes
COPY . .                          # Copy code last (changes most frequently)
CMD ["python", "app.py"]
```

#### Multi-Stage Builds

Use multi-stage builds to reduce final image size:

```dockerfile
# ✅ EXCELLENT: Build stage + Runtime stage
# Stage 1: Build
FROM python:3.12 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim
WORKDIR /app
# Copy only installed packages, not build tools
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

#### Use .dockerignore

Create a `.dockerignore` file to exclude unnecessary files:

```dockerignore
# Git and CI/CD
.git
.github
.gitignore

# Python
__pycache__
*.pyc
*.pyo
*.egg-info
.pytest_cache
.coverage

# Virtual environments
venv/
env/
.venv/

# IDE
.vscode/
.idea/
*.swp

# Documentation
README.md
docs/
*.md

# Tests
tests/
test_*.py

# Local configs
.env.local
.env.development
```

#### Cache Optimization Tips

**1. Group Related Commands**:

```dockerfile
# ❌ BAD: Multiple RUN commands = multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# ✅ GOOD: Single RUN command = one layer
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**2. Pin Versions for Reproducibility**:

```dockerfile
# ❌ BAD: Unpredictable builds
FROM python:3.12
RUN pip install flask

# ✅ GOOD: Reproducible builds
FROM python:3.12.0-slim
RUN pip install flask==3.0.0
```

**3. Use BuildKit Cache Mounts** (Advanced):

```dockerfile
# Mount pip cache to speed up dependency installation
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
```

#### Language-Specific Best Practices

**Python**:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies first (rarely change)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install dependencies (change occasionally)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code (changes frequently)
COPY . .

CMD ["python", "app.py"]
```

**Node.js**:

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

CMD ["node", "index.js"]
```

**Go**:

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o main .

# Runtime stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]
```

#### Build Cache Verification

The workflow automatically uses registry cache. Check build logs for:

```text
✅ Good cache usage:
#5 [2/4] COPY requirements.txt .
#5 CACHED

✅ Efficient build:
#8 [4/4] RUN pip install -r requirements.txt
#8 CACHED
```

```text
⚠️ Poor cache usage (rebuilding every time):
#5 [2/4] COPY requirements.txt .
#5 0.123s

#8 [4/4] RUN pip install -r requirements.txt
#8 45.234s  ← Taking too long, not using cache
```

#### Dockerfile Checklist

Before committing your Dockerfile, verify:

- [ ] Base image uses specific version tag (not `latest`)
- [ ] Dependencies installed before copying code
- [ ] `.dockerignore` file exists and excludes unnecessary files
- [ ] Multi-stage build used when applicable
- [ ] Commands grouped to minimize layers
- [ ] No secrets or credentials in image
- [ ] Final image size is reasonable (< 500MB for most apps)
- [ ] Application runs on the correct port specified in workflow

### 3. Configuration Management

- Use environment-specific config files
- Mount configs via the `config-path` parameter

### 4. Testing

- Ensure tests pass locally first
- Add comprehensive test coverage
- Tests must complete successfully for deployment

## Common Workflows

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes and commit
git add .
git commit -m "Add new feature"

# 3. Push to trigger: Test + Build + PR creation
git push origin feature/new-feature

# 4. Review the auto-created PR, then merge via GitHub UI

# 5. Master branch auto-deploys after merge
```

### Release Workflow with Tags

```bash
# 1. Ensure you're on master and up to date
git checkout master
git pull origin master

# 2. Create a version tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# 3. Push tag to trigger: Test + Build + Deploy
git push origin v1.0.0

# 4. Monitor deployment in GitHub Actions
# 5. Application is deployed with tag v1.0.0
```

### Hotfix Workflow

```bash
# 1. Create hotfix branch from master
git checkout master
git checkout -b hotfix/critical-bug

# 2. Fix the bug
git add .
git commit -m "Fix critical bug"

# 3. Push and create PR
git push origin hotfix/critical-bug

# 4. After PR approval, merge to master
# 5. Create hotfix tag for deployment
git checkout master
git pull origin master
git tag v1.0.1
git push origin v1.0.1
```

## Troubleshooting

### Common Issues

**Tests Failing**:

- Check GitHub Actions logs for test output
- Run tests locally: `make test` or your configured test command
- Ensure all dependencies are installed

**Docker Build Failing**:

- Verify Dockerfile exists at specified path
- Check Docker build context includes necessary files
- Review `.dockerignore` file
- Test build locally: `docker build -f <dockerfile> -t test .`

**Deployment Not Triggering**:

- Verify you pushed to `master`/`main`, created a tag, or published a release
- Check workflow file has correct triggers configured
- Review job conditions in GitHub Actions logs

**Application Not Accessible**:

- Check deployment logs in Kubernetes: `kubectl logs -n <org-name> deployment/<project-name>`
- Verify port configuration matches your application
- Check ingress configuration and DNS
- Ensure health checks are passing

### Getting Help

1. Check the workflow logs in GitHub Actions
2. Review pod logs in Kubernetes
3. Contact the DevOps team
4. Create an issue in the `.github` repository

## Examples in the Repository

Check out the example usage in:

- `.github/workflows/example-usage.yaml`
- `src/apps/httpbin/` for a complete example

## Security Notes

- Docker credentials are managed automatically
- TLS certificates are auto-generated
- Configs are mounted to image in runtime
- Multi-platform builds ensure compatibility

## Quick Reference

### Trigger Configuration Cheat Sheet

| Goal                                 | Configuration                          | Command/Action                                      |
| ------------------------------------ | -------------------------------------- | --------------------------------------------------- |
| **Deploy on every commit to master** | `on: push: branches: [master]`         | `git push origin master`                            |
| **Deploy with version tags**         | `on: push: tags: ['v*']`               | `git tag v1.0.0 && git push origin v1.0.0`          |
| **Deploy on GitHub Release**         | `on: release: types: [published]`      | Create release via GitHub UI or `gh release create` |
| **Test PRs without deploying**       | `on: pull_request: branches: [master]` | Create PR via GitHub UI                             |
| **Auto-create PRs from features**    | `on: push: branches: ['feature/**']`   | `git push origin feature/my-feature`                |
| **Manual deployment**                | `on: workflow_dispatch:`               | Trigger via GitHub Actions UI                       |

### Deployment Decision Matrix

| Trigger Type | Branch/Tag      | Tests | Build | Deploy        | Create PR |
| ------------ | --------------- | ----- | ----- | ------------- | --------- |
| Push         | `feature/*`     | ✅    | ✅    | ❌            | ✅        |
| Push         | `master`/`main` | ✅    | ✅    | ✅            | ❌        |
| Push         | Tag `v*`        | ✅    | ✅    | ✅            | ❌        |
| Pull Request | To `master`     | ✅    | ✅    | ❌            | ❌        |
| Release      | Published       | ✅    | ✅    | ✅            | ❌        |
| Manual       | Any             | ✅    | ✅    | Conditional\* | ❌        |

\* Manual triggers deploy only if on master/main branch or tag

### Common Tag Patterns

| Pattern     | Matches                | Use Case              |
| ----------- | ---------------------- | --------------------- |
| `v*`        | v1.0.0, v2.1.3, vAny   | All versions          |
| `v[0-9]+.*` | v1.0.0, v2.1.3         | Numeric versions only |
| `v*.*.*`    | v1.0.0, v2.1.3         | Semantic versioning   |
| `v*-rc*`    | v1.0.0-rc1, v2.0.0-rc2 | Release candidates    |
| `release-*` | release-2024.11.10     | Date-based releases   |
| `prod-*`    | prod-v1, prod-latest   | Production tags       |

## Quick Reference Card for Developers

### 📦 Dockerfile Best Practices

```dockerfile
# ✅ DO THIS - Maximize cache efficiency
FROM python:3.12-slim              # Pin specific version
WORKDIR /app
COPY requirements.txt .            # Dependencies first
RUN pip install -r requirements.txt
COPY . .                           # Code last
CMD ["python", "app.py"]

# ❌ NOT THIS - Poor cache usage
FROM python:latest                 # Unpredictable
WORKDIR /app
COPY . .                          # Everything at once
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

### 🚀 Build Speed Tips

| Action                     | Impact     | Build Time         |
| -------------------------- | ---------- | ------------------ |
| Well-structured Dockerfile | ⭐⭐⭐⭐⭐ | 30s (cached)       |
| `.dockerignore` file       | ⭐⭐⭐⭐   | -10-20s            |
| Multi-stage builds         | ⭐⭐⭐     | Smaller image      |
| Pin dependency versions    | ⭐⭐       | Reproducible       |
| Poor structure             | ❌         | 5+ min every build |

### 📋 Pre-Push Checklist

Before pushing your code, ensure:

```bash
# 1. Dockerfile exists and is optimized
[ -f Dockerfile ] && echo "✅ Dockerfile found"

# 2. .dockerignore exists
[ -f .dockerignore ] && echo "✅ .dockerignore found"

# 3. Test build locally (optional but recommended)
docker build -t test-build .

# 4. Run tests locally
make test  # or your test command

# 5. Push and let CI/CD handle the rest
git push origin feature/my-feature
```

### 🎯 Common Mistakes to Avoid

| Mistake                      | Problem                                | Solution                   |
| ---------------------------- | -------------------------------------- | -------------------------- |
| Using `COPY . .` before deps | Cache invalidated on every code change | Copy deps first, code last |
| Missing `.dockerignore`      | Large build context, slow uploads      | Create `.dockerignore`     |
| Using `latest` tags          | Unpredictable builds                   | Pin specific versions      |
| Multiple RUN commands        | Too many layers                        | Combine with `&&`          |
| Not testing locally          | CI fails, wasted time                  | Build and test before push |
| Large final image            | Slow deployments                       | Use multi-stage builds     |

## 💡 Usage Examples

Here are some common ways to use this workflow in your repository's `.github/workflows/ci.yml`.

### 1. Standard Python Service (Default)

Ideal for Python 3.12 projects using Poetry/uv.

```yaml
name: CI/CD

on:
  push:
    branches: ["**"]
  release:
    types: [published]

jobs:
  build-and-deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "my-python-service"
      # Uses defaults: Python 3.12, make test, port 8000
    secrets: inherit
```

### 2. Python Service with Specific Version

If you need a specific Python version (e.g., 3.11).

```yaml
name: CI/CD

jobs:
  build-and-deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "legacy-service"
      install-python: "3.11"
      test-command: "pytest tests/"
    secrets: inherit
```

### 3. Non-Python Service (Node.js, Go, etc.)

Disable Python setup to save time and avoid errors.

```yaml
name: CI/CD

jobs:
  build-and-deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "frontend-app"
      install-python: "false" # Skip Python setup
      test-command: "npm test" # Use your language's test command
      port: 3000 # Adjust port for your app
    secrets: inherit
```

### 4. Full Configuration

Example with secrets, custom ingress, and monitoring enabled.

```yaml
name: CI/CD

jobs:
  build-and-deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "payment-api"
      install-python: "3.12"

      # Networking
      port: 8080
      ingress-domain: "api" # https://api.urieljsc.com
      root-path: "/v1"

      # Config & Secrets
      config-path: "config/prod.yaml"
      env-file: ".env.production"

      # Monitoring
      service-monitor: true
      prometheus-rule: true

      # PR Management
      pr-reviewers: "lead-dev,architect"
    secrets: inherit
```

## Support

For questions or issues:

- 📧 Contact: @duchuyvp
- 🐛 Issues: Create issue in tex-corver/.github repository
- 📖 Docs: This guide and inline comments in workflow files

---
