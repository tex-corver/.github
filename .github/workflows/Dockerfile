# Base image matching your current runner
FROM ghcr.io/actions/actions-runner:latest

# 1. Install basic tools and Make
# build-essential includes make, gcc, g++, etc.
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    software-properties-common \
    gpg-agent \
    && sudo rm -rf /var/lib/apt/lists/*

# 2. Install Python 3.12
# Ubuntu 22.04 (jammy) comes with 3.10, so we use deadsnakes PPA for 3.12
RUN sudo add-apt-repository ppa:deadsnakes/ppa -y && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    && sudo rm -rf /var/lib/apt/lists/*

# 3. Install uv (High-performance Python package installer)
# Copying directly from the official image is the cleanest way
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# 4. Install Poetry
ENV POETRY_HOME=/opt/poetry
RUN curl -sSL https://install.python-poetry.org | sudo POETRY_HOME=/opt/poetry python3.12 - && \
    sudo ln -s /opt/poetry/bin/poetry /usr/local/bin/poetry

# 5. (Optional) Pre-install common Python tools to speed up workflows further
# This populates the cache
# RUN uv pip install --system ruff pytest black
