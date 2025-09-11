# Build and Push Docker Image Workflow Guide

This guide will help you use the predefined 'Build and Push Docker Image' GitHub Actions workflow for your projects.

## Overview

The workflow is a reusable GitHub Action that automates the complete CI/CD pipeline for Docker-based applications. It handles:

- 🧪 Running tests
- 🐳 Building and pushing Docker images to our registry
- 🚀 Deploying to development environment
- ✅ Verifying deployment
- 📝 Creating pull requests for `master`

## Quick Start

### 1. Basic Usage

Create a workflow file in your repository (e.g., `.github/workflows/deploy.yaml`):

```yaml
name: Deploy Application

on:
  push:
    branches: [dev, feature/*]
  workflow_dispatch:

jobs:
  deploy:
    uses: tex-corver/.github/.github/workflows/docker-build-push.yaml@master
    with:
      ...
      ...
```

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

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `project-name` | string | Project/application name. Require | `"document-manager"` |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `org-name` | string | Repository owner. | Organization/namespace name. This value is used for suffix of image.  |
| `docker-build-file` | string | `"Dockerfile"` | Path to Dockerfile will be used for `docker build`. |
| `docker-build-context` | string | `"."` | Docker build context |
| `port` | number | `8000` | Application port |
| `ingress` | boolean | `true` | Enable https request to application |
| `fastapi-root-path` | string | `""` | Prefix path for http requests to application |
| `config-path` | string | `"README.md"` | Path to config. You must have README.md in your repo if you don't provide this parameter. |

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
        service: [
          schedule-manager, 
          dataset-manager, 
          execution-manager, 
          worker
        ]
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

## Best Practices

### 1. Branch Strategy

- Use `dev` branch for development deployments
- Create feature branches for new features
- Workflow auto-creates PRs to master

### 2. Docker Optimization

- Use multi-stage builds
- Minimize image layers
- Use `.dockerignore`

### 3. Configuration Management

- Use environment-specific config files
- Mount configs via the `config-path` parameter

### 4. Testing

- Ensure tests pass locally first
- Add comprehensive test coverage
- Tests must complete successfully for deployment

## Troubleshooting

- Check GitHub Actions logs
- Verify Dockerfile exists
- Ensure tests pass locally

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

## Support

For questions or issues:

- 📧 Contact: @duchuyvp
- 🐛 Issues: Create issue in tex-corver/.github repository
- 📖 Docs: This guide and inline comments in workflow files

---
