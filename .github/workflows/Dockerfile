# Base image matching your current runner
FROM ghcr.io/actions/actions-runner:latest

# 1. Install basic tools
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    curl \
    git \
    software-properties-common \
    gpg-agent \
    && sudo rm -rf /var/lib/apt/lists/*

# 2. Install Build Essential (Split to reduce layer size)
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    build-essential \
    && sudo rm -rf /var/lib/apt/lists/*

# 3. Add Python PPA
RUN sudo add-apt-repository ppa:deadsnakes/ppa -y

# 4. Install Python 3.12 Runtime (Split to reduce layer size)
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python-is-python3 \
    && sudo rm -rf /var/lib/apt/lists/*

# 5. Install Python Dev tools (Split to reduce layer size)
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    python3.12-dev \
    python3-pip \
    && sudo rm -rf /var/lib/apt/lists/*

# Make python3 default to python3.12
RUN sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2

# 3. Install uv (High-performance Python package installer)
# Copying directly from the official image is the cleanest way
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# 4. Install Poetry
RUN curl -sSL https://install.python-poetry.org | sudo POETRY_HOME=/opt/poetry python3.12 - && \
    sudo ln -s /opt/poetry/bin/poetry /usr/local/bin/poetry

# 5. (Optional) Pre-install common Python tools to speed up workflows further
# This populates the cache
# RUN uv pip install --system ruff pytest black
