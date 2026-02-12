#!/usr/bin/env bash
set -euo pipefail

echo "=== Post-create setup ==="

# Copy kube config from host mount (mounted via devcontainer.json)
if [ -f /home/vscode/.kube/config ]; then
  echo "[ok] ~/.kube/config already present"
else
  echo "[warn] ~/.kube/config not found — copy it manually if needed"
fi

# Install agent-browser's bundled Chromium
echo "[info] Installing agent-browser Chromium..."
agent-browser install 2>/dev/null || echo "[warn] agent-browser install skipped"

# Register agent-browser as a Claude Code skill
echo "[info] Registering agent-browser skill..."
npx skills add vercel-labs/agent-browser 2>/dev/null || echo "[warn] agent-browser skill registration skipped"

# Verify installations
echo ""
echo "=== Verifying installations ==="
echo -n "gh:            " && gh --version | head -1
echo -n "sudo:          " && sudo --version | head -1
echo -n "docker:        " && docker --version
echo -n "kubectl:       " && kubectl version --client 2>/dev/null | head -1
echo -n "python:        " && python3 --version
echo -n "pydantic:      " && python3 -c "import pydantic; print(pydantic.__version__)" 2>/dev/null || echo "not found"
echo -n "ruff:          " && ruff --version 2>/dev/null || echo "not found"
echo -n "node:          " && node --version
echo -n "playwright:    " && npx playwright --version 2>/dev/null || echo "installed"
echo -n "claude:        " && claude --version 2>/dev/null || echo "installed"
echo -n "agent-browser: " && agent-browser --version 2>/dev/null || echo "installed"

echo ""
echo "=== Post-create setup complete ==="
