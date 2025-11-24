# Lint and Test Workflow Guide

This guide will help you use the predefined 'Lint and Test' GitHub Actions workflow for your projects.

## Overview

The workflow is a reusable GitHub Action designed for Continuous Integration (CI) checks. It focuses on code quality and correctness without the overhead of building and pushing Docker images. It handles:

- 🐍 Setting up Python environment (optional)
- 🔍 Running linting checks
- 🧪 Running tests
- 🐳 Verifying Docker build

## Usage Examples

Here are common ways to use this workflow in your repository's `.github/workflows/lint-test.yaml`.

### 1. Standard Python Project (Default)

Ideal for Python 3.12 projects using Poetry/uv.

```yaml
name: CI

on:
  pull_request:
    branches: [master, main]

jobs:
  check-quality:
    uses: tex-corver/.github/.github/workflows/lint-test.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "my-service"
      # Uses defaults: Python 3.12, make lint, make test
```

### 2. Python Project with Specific Version

If you need a specific Python version (e.g., 3.11).

```yaml
name: CI

jobs:
  check-quality:
    uses: tex-corver/.github/.github/workflows/lint-test.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "legacy-service"
      install-python: "3.11"
      lint-command: "flake8 ."
      test-command: "pytest"
```

### 3. Non-Python Project (Node.js, Go, etc.)

Disable Python setup and use your language's commands.

```yaml
name: CI

jobs:
  check-quality:
    uses: tex-corver/.github/.github/workflows/lint-test.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "frontend-app"
      install-python: "false"
      lint-command: "make lint"
      test-command: "poetry run pytest"
```

### 4. With Docker Build Check

Verify that your Dockerfile builds correctly, using the registry cache for speed.

```yaml
name: CI

jobs:
  check-quality:
    uses: tex-corver/.github/.github/workflows/lint-test.yaml@master
    with:
      org-name: "tex-corver"
      project-name: "api-service"
      docker-build-file: "src/apps/api/Dockerfile"
      docker-build-context: "src/apps/api"
```

## Input Parameters

### General Configuration

| Parameter      | Type   | Default          | Description                               |
| -------------- | ------ | ---------------- | ----------------------------------------- |
| `org-name`     | string | Repository owner | Organization name (e.g., `"tex-corver"`). |
| `project-name` | string | `"project"`      | Project name, used for cache keys.        |

### Other Configuration

| Parameter              | Type   | Default        | Description                                                    |
| ---------------------- | ------ | -------------- | -------------------------------------------------------------- |
| `install-python`       | string | `"3.12"`       | Python version. Set to `""` or `"false"` to skip installation. |
| ---------------------- | ------ | -------------- | ------------------------------------------                     |
| `lint-command`         | string | `"make lint"`  | Command to run linting (e.g., `"flake8"`).                     |
| `test-command`         | string | `"make test"`  | Command to run tests (e.g., `"pytest"`).                       |
| ---------------------- | ------ | -------------- | ------------------------------------------                     |
| `docker-build-file`    | string | `"Dockerfile"` | Path to Dockerfile.                                            |
| `docker-build-context` | string | `"."`          | Build context directory.                                       |

## When to use this vs. Docker Build & Push?

| Feature        | Lint & Test Workflow    | Docker Build & Push Workflow      |
| :------------- | :---------------------- | :-------------------------------- |
| **Speed**      | ⚡ Fast (no image push) | 🐢 Slower (builds & pushes image) |
| **Purpose**    | PR checks, Code Quality | Deployment, Release               |
| **Artifacts**  | None                    | Docker Image in Registry          |
| **Deployment** | No                      | Yes (to Dev/Staging)              |

**Recommendation**:

- Use **Lint & Test** for Pull Requests to save time and resources.
- Use **Docker Build & Push** for merges to `master`/`main` or when you specifically need to test the deployment.
