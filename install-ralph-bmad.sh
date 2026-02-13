#!/bin/bash

# Install Ralph-Enhanced BMAD Method to a target project
# ======================================================
# This script installs the forked BMAD method (with ralph integration)
# to a target project directory, copies ralph scripts, and applies
# agent customizations.
#
# Usage: ./install-ralph-bmad.sh <target-directory>
# Example: ./install-ralph-bmad.sh /path/to/my-project

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TARGET_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMAD_SRC="$SCRIPT_DIR/BMAD-METHOD"

if [ -z "$TARGET_DIR" ]; then
  echo -e "${RED}Error: Missing required argument${NC}"
  echo ""
  echo "Usage: $0 <target-directory>"
  echo "Example: $0 /path/to/my-project"
  echo ""
  echo "Installs ralph-enhanced BMAD method to the target project."
  echo "This includes:"
  echo "  - BMAD Method (forked with ralph workflows and agent changes)"
  echo "  - ralph.sh (autonomous loop script)"
  echo "  - ralph-bmad.sh (BMAD-aware wrapper with status tracking)"
  echo "  - Agent customizations (.customize.yaml files)"
  exit 1
fi

# Verify BMAD source exists
if [ ! -d "$BMAD_SRC" ]; then
  echo -e "${RED}Error: BMAD-METHOD directory not found at $BMAD_SRC${NC}"
  echo "Please ensure the BMAD-METHOD submodule is initialized:"
  echo "  git submodule update --init --recursive"
  exit 1
fi

# Verify BMAD CLI exists
if [ ! -f "$BMAD_SRC/tools/cli/index.js" ]; then
  echo -e "${RED}Error: BMAD CLI not found at $BMAD_SRC/tools/cli/index.js${NC}"
  echo "The BMAD-METHOD submodule may be incomplete."
  exit 1
fi

# Resolve target directory
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || mkdir -p "$TARGET_DIR" && cd "$TARGET_DIR" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Ralph-Enhanced BMAD Method Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Source: ${GREEN}$BMAD_SRC${NC}"
echo -e "Target: ${GREEN}$TARGET_DIR${NC}"
echo ""

# Step 1: Run standard BMAD install using our forked submodule
echo -e "${BLUE}Step 1: Installing BMAD Method (forked with ralph integration)...${NC}"
echo ""
node "$BMAD_SRC/tools/cli/index.js" install --directory "$TARGET_DIR"

# Step 2: Copy ralph scripts
echo ""
echo -e "${BLUE}Step 2: Installing ralph scripts...${NC}"

if [ -f "$SCRIPT_DIR/ralph-loop-quickstart/ralph.sh" ]; then
  cp "$SCRIPT_DIR/ralph-loop-quickstart/ralph.sh" "$TARGET_DIR/ralph.sh"
  echo -e "  ${GREEN}Installed: ralph.sh${NC}"
else
  echo -e "  ${YELLOW}Warning: ralph-loop-quickstart/ralph.sh not found, skipping${NC}"
fi

if [ -f "$SCRIPT_DIR/ralph-bmad.sh" ]; then
  cp "$SCRIPT_DIR/ralph-bmad.sh" "$TARGET_DIR/ralph-bmad.sh"
  echo -e "  ${GREEN}Installed: ralph-bmad.sh${NC}"
else
  echo -e "  ${YELLOW}Warning: ralph-bmad.sh not found, skipping${NC}"
fi

chmod +x "$TARGET_DIR/ralph.sh" "$TARGET_DIR/ralph-bmad.sh" 2>/dev/null || true

# Step 3: Copy agent customization files (memories/context)
echo ""
echo -e "${BLUE}Step 3: Installing agent customization files...${NC}"

AGENT_CONFIG_DIR="$TARGET_DIR/_bmad/_config/agents"
if [ -d "$AGENT_CONFIG_DIR" ]; then
  for f in "$SCRIPT_DIR"/customizations/agents/*.customize.yaml; do
    if [ -f "$f" ]; then
      BASENAME=$(basename "$f")
      # Only copy if the file doesn't already exist (don't overwrite user customizations)
      if [ ! -f "$AGENT_CONFIG_DIR/$BASENAME" ]; then
        cp "$f" "$AGENT_CONFIG_DIR/"
        echo -e "  ${GREEN}Installed: $BASENAME${NC}"
      else
        echo -e "  ${YELLOW}Skipped (already exists): $BASENAME${NC}"
      fi
    fi
  done
else
  echo -e "  ${YELLOW}Warning: Agent config directory not found at $AGENT_CONFIG_DIR${NC}"
  echo -e "  ${YELLOW}Agent customizations will need to be copied manually.${NC}"
fi

# Step 4: Recompile agents to apply customizations
echo ""
echo -e "${BLUE}Step 4: Recompiling agents with customizations...${NC}"
node "$BMAD_SRC/tools/cli/index.js" install --directory "$TARGET_DIR" --action compile-agents

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Ralph-enhanced BMAD Method installed at: $TARGET_DIR"
echo ""
echo -e "${BLUE}Key files:${NC}"
echo "  _bmad/                      - BMAD framework (with ralph workflows)"
echo "  ralph.sh                    - Ralph loop script"
echo "  ralph-bmad.sh               - BMAD-aware wrapper (status tracking)"
echo "  _bmad/_config/agents/       - Agent customizations"
echo ""
echo -e "${BLUE}Workflow Progression:${NC}"
echo "  Phase 1-3: Analysis → Planning → Solutioning (unchanged)"
echo "  Phase 4:   CS → DS → CR"
echo "             CS  = Create Story (now includes Ralph Tasks JSON)"
echo "             DS  = Dev Story (DEFAULT: Ralph loop, fresh context per task)"
echo "             DSC = Dev Story Classic (fallback: original subagent)"
echo "             CR  = Code Review (unchanged)"
echo "             QA  = QA Automate (DEFAULT: Ralph loop)"
echo "             QAC = QA Automate Classic (fallback: original)"
echo "             RUX = Ralph UX Story (UX implementation via Ralph)"
echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo "  1. Load SM agent and run CS (Create Story)"
echo "  2. Load Dev agent and run DS (Ralph Dev Story)"
echo "  3. Load Dev agent and run CR (Code Review)"
echo ""
