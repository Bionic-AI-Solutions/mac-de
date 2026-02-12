# Toolchain Reference

Dockerfile snippets for adding toolchains. Always place these BEFORE the `USER vscode` line.

## Node.js

```dockerfile
ARG NODE_MAJOR=22

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*
```

### Common global packages

```dockerfile
# Playwright (browser automation)
RUN npm install -g playwright@latest \
    && npx playwright install --with-deps chromium

# Claude Code CLI + agent-browser
RUN npm install -g @anthropic-ai/claude-code agent-browser
```

## Python + Pydantic

```dockerfile
ARG PYTHON_VERSION=3.12

RUN apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-venv \
        python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 \
    && ln -sf /usr/bin/python3 /usr/bin/python

# Install pipx for isolated tool installs
RUN python3 -m pip install --break-system-packages pipx \
    && pipx ensurepath

# Install common Python tools
RUN python3 -m pip install --break-system-packages \
        pydantic \
        pydantic-settings \
        uvicorn \
        fastapi \
        httpx \
        ruff
```

### Poetry variant

```dockerfile
RUN python3 -m pip install --break-system-packages poetry
```

### uv variant (fast Python package manager)

```dockerfile
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Docker CLI (client only)

Connects to host Docker engine via mounted socket.

```dockerfile
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*
```

Requires mount in devcontainer.json:
```json
"mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
]
```

And group setup:
```dockerfile
RUN groupadd -f docker && usermod -aG docker vscode
```

## kubectl

```dockerfile
ARG KUBECTL_VERSION=v1.31.4

RUN curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl
```

Requires mount in devcontainer.json:
```json
"mounts": [
    "source=${localEnv:HOME}/.kube,target=/home/vscode/.kube,type=bind,consistency=cached"
]
```

And directory setup:
```dockerfile
RUN mkdir -p /home/vscode/.kube && chown -R vscode:vscode /home/vscode/.kube
```

## GitHub CLI (gh)

```dockerfile
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
```

## Base dependencies (always include)

```dockerfile
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
```
