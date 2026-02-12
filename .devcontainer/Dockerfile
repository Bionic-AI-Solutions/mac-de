FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG KUBECTL_VERSION=v1.31.4
ARG NODE_MAJOR=22
ARG PYTHON_VERSION=3.12

# Install base dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        sudo \
        git \
        wget \
        unzip \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN (type -p wget >/dev/null || apt-get install -y wget) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (client only — connects to host Docker engine via socket)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

# Install Node.js (needed for Playwright and Claude Code CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright globally and its system dependencies
RUN npm install -g playwright@latest \
    && npx playwright install --with-deps chromium

# Install Claude Code CLI and agent-browser (browser automation for AI agents)
RUN npm install -g @anthropic-ai/claude-code agent-browser

# Install Python and Pydantic
RUN apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-venv \
        python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 \
    && ln -sf /usr/bin/python3 /usr/bin/python

RUN python3 -m pip install --break-system-packages \
        pydantic \
        pydantic-settings \
        ruff

# Add vscode user to the docker group so it can access the Docker socket
RUN groupadd -f docker && usermod -aG docker vscode

# Set up kube config directory for vscode user
RUN mkdir -p /home/vscode/.kube && chown -R vscode:vscode /home/vscode/.kube

# Set up projects directory
RUN mkdir -p /home/vscode/projects && chown -R vscode:vscode /home/vscode/projects

USER vscode
