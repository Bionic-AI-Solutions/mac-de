#!/usr/bin/env bash
set -euo pipefail

echo "=== Post-create setup ==="

# {{POST_CREATE_STEPS}}

# Verify installations
echo ""
echo "=== Verifying installations ==="
# {{VERIFY_COMMANDS}}

echo ""
echo "=== Post-create setup complete ==="
