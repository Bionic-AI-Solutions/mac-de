---
name: init-project
description: Initialize a new project with Ralph-enhanced BMAD Method. Sets up the full BMAD framework with ralph autonomous loop integration, creates a GitHub repo, registers it as a git submodule in the parent workspace, and configures the devcontainer. Use when the user needs to create or bootstrap a new project from scratch.
---

# Init Project

Bootstrap a new project directory with Ralph-enhanced BMAD Method — the full autonomous AI development framework.

## Prerequisites

These must be available in the environment:
- **Node.js >= 20** and **npm**
- **git**
- **BMAD-METHOD submodule** at the path resolved by scanning upward from the workspace root for a `BMAD-METHOD/` directory containing `tools/cli/bmad-cli.js`

## Workflow

### Step 1: Resolve target directory

Determine the target project directory:
- If the user provides a path, use it (create it if it doesn't exist)
- If the user gives only a project name, create it under the current workspace root
- If no path is given, ask the user for one

Resolve to an absolute path and confirm with the user before proceeding.

### Step 2: Locate the BMAD-METHOD source

Find the `BMAD-METHOD/` directory by searching:
1. Sibling of the target directory
2. Parent of the target directory
3. Common workspace roots (`/workspaces/*/BMAD-METHOD`)

The directory must contain `tools/cli/bmad-cli.js` and `scripts/install-ralph-bmad.sh`.

If not found, tell the user and stop.

### Step 3: Initialize git repository

Initialize a local git repo inside the target directory. This is temporary — the directory will be converted to a submodule in Step 10.

```bash
cd <target-dir>
git init
```

### Step 4: Create .gitignore

If `.gitignore` does not exist in the target directory, create one with sensible defaults:

```
# Dependencies
node_modules/
.pnp.*
.yarn/

# Build output
dist/
build/
.next/
out/

# Environment
.env
.env.local
.env.*.local

# OS files
.DS_Store
Thumbs.db

# IDE
.idea/
*.swp
*.swo

# Logs
*.log
npm-debug.log*

# Test coverage
coverage/

# BMAD output (generated artifacts)
_bmad-output/
```

If `.gitignore` already exists, do NOT overwrite it.

### Step 5: Run the Ralph-BMAD installer

Execute the installer script:

```bash
<bmad-method-path>/scripts/install-ralph-bmad.sh <target-dir>
```

This is a single command that handles everything:
- Installs npm dependencies for the BMAD CLI (if needed)
- Runs `bmad-cli.js install` with `--modules bmm --tools claude-code -y`
- Copies `ralph.sh` and `ralph-bmad.sh` to the project root
- Copies `.customize.yaml` agent overlays
- Recompiles all agents with ralph customizations applied

Wait for it to complete and verify exit code is 0.

### Step 6: Symlink workspace skills

Make all skills from the parent workspace available in the new project. This allows the user to change their devcontainer `workspaceFolder` to this project and retain full skill access.

1. Create `<target-dir>/.claude/skills/` if it doesn't already exist
2. Find the parent workspace root by scanning upward from the target directory for a directory containing `.devcontainer/` — this is the workspace root
3. Discover all skills by scanning these locations under the workspace root:
   - `.claude/skills/*/SKILL.md` — skills installed directly
   - `.agents/skills/*/SKILL.md` — skills installed via agents
4. For each discovered skill, resolve its real path (follow any existing symlinks to their final target) and create a symlink in `<target-dir>/.claude/skills/<skill-name>` pointing to that resolved real path
5. Skip any skill that already exists in the target (e.g., if the BMAD installer already created entries in `.claude/`)

Example:
```bash
# For a skill at /workspaces/mac-de/.claude/skills/devcontainer (real directory)
ln -s /workspaces/mac-de/.claude/skills/devcontainer <target-dir>/.claude/skills/devcontainer

# For a skill at /workspaces/mac-de/.claude/skills/agent-browser -> /workspaces/mac-de/.agents/skills/agent-browser
# Resolve the symlink first, then link to the real path
ln -s /workspaces/mac-de/.agents/skills/agent-browser <target-dir>/.claude/skills/agent-browser
```

### Step 7: Create CLAUDE.md

Create a `CLAUDE.md` at the project root with the following template. Replace `<project-name>` with the directory name and `<workspace-root>` with the resolved parent workspace root path:

```markdown
# <project-name>

## Project Structure

- `_bmad/` — BMAD framework (core + BMM module)
- `_bmad-output/` — Generated planning and implementation artifacts (gitignored)
- `.claude/commands/` — BMAD slash commands for Claude Code
- `.claude/skills/` — Symlinked skills from parent workspace
- `ralph.sh` — Ralph Wiggum autonomous development loop engine
- `ralph-bmad.sh` — BMAD wrapper with story status tracking

## BMAD Workflow

1. `/bmad-agent-bmm-pm` — Create Product Brief, then PRD
2. `/bmad-agent-bmm-architect` — Create Architecture
3. `/bmad-agent-bmm-sm` — Sprint planning and story creation (CS)
4. `/bmad-agent-bmm-dev` — Dev Story (DS) for implementation
5. `/bmad-agent-bmm-dev` — Code Review (CR)
6. `/bmad-agent-bmm-qa` — QA Automate

Ralph autonomous loop triggers:
- **DS** — Dev Story (Ralph loop, default)
- **DSC** — Dev Story Classic (manual)
- **QA** — QA Automate (Ralph loop, default)
- **QAC** — QA Classic (manual)
- **RUX** — Ralph UX Story

## Available Skills

<list each symlinked skill name and a one-line description from its SKILL.md front matter>

## Environment

- Devcontainer workspace: `<workspace-root>/<project-name>`
- Parent repo: `<workspace-root>` (contains BMAD-METHOD submodule, .devcontainer, shared skills)
- BMAD-METHOD submodule: `<workspace-root>/BMAD-METHOD`

## Conventions

- Planning artifacts go in `_bmad-output/planning-artifacts/`
- Implementation artifacts go in `_bmad-output/implementation-artifacts/`
- `_bmad-output/` is gitignored — commit artifacts selectively when needed
- Use BMAD slash commands to engage the right agent persona for each task
```

### Step 8: Update devcontainer workspace folder

Update the devcontainer configuration so the user can simply rebuild the container to work in the new project:

1. Find `<workspace-root>/.devcontainer/devcontainer.json`
2. Read the current `workspaceFolder` value
3. Set `workspaceFolder` to `"/workspaces/${localWorkspaceFolderBasename}/<project-name>"`
4. If `postCreateCommand` uses a relative path to `.devcontainer/post-create.sh`, update it to the absolute path `<workspace-root>/.devcontainer/post-create.sh`

This ensures that after a container rebuild, VSCode opens directly in the new project with all skills and BMAD commands available.

### Step 9: Initial commit

Stage and commit the initialized project:

```bash
cd <target-dir>
git add -A
git commit -m "chore: initialize project with Ralph-enhanced BMAD Method"
```

### Step 10: Create GitHub repository and register as submodule

This step converts the project from a plain directory into a proper git submodule of the parent workspace, giving it its own project root so Claude Code discovers its `CLAUDE.md`, `.claude/commands/`, and `.claude/skills/` correctly.

#### 10a: Detect GitHub owner

Extract the GitHub owner/org from the parent workspace's remote:

```bash
cd <workspace-root>
GITHUB_OWNER=$(git remote get-url origin | sed -n 's|.*github.com[:/]\([^/]*\)/.*|\1|p')
```

If the parent has no GitHub remote or the owner cannot be parsed, ask the user for the GitHub owner/org name.

#### 10b: Check gh authentication

```bash
gh auth status
```

If not authenticated, tell the user to run `gh auth login` and stop. Do not proceed without authentication.

#### 10c: Create the remote repository

Create a private GitHub repo under the detected owner and push the initial commit:

```bash
gh repo create ${GITHUB_OWNER}/<project-name> --private \
  --description "<project-name> - BMAD Method project" \
  --source <target-dir> --push
```

Verify the command succeeds and note the returned repository URL.

#### 10d: Convert to submodule

Remove the project directory and re-add it as a git submodule in the parent workspace:

```bash
cd <workspace-root>
rm -rf <project-name>
git submodule add https://github.com/${GITHUB_OWNER}/<project-name>.git <project-name>
```

This clones the repo back into the same path, but now as a proper submodule with its own `.git` identity.

#### 10e: Commit submodule registration in parent

Stage and commit the submodule addition and devcontainer changes in the parent workspace:

```bash
cd <workspace-root>
git add .gitmodules <project-name> .devcontainer/devcontainer.json
git commit -m "feat: add <project-name> as submodule"
```

### Step 11: Summary

Display what was set up:

```
Project initialized at: <target-dir>
GitHub repo: https://github.com/${GITHUB_OWNER}/<project-name> (private)
Registered as submodule in: <workspace-root>

Installed:
  _bmad/              BMAD framework (27 workflows, 10 agents)
  .claude/commands/   Claude Code slash commands
  .claude/skills/     Symlinked skills from parent workspace
  CLAUDE.md           Project context for Claude Code
  ralph.sh            Ralph loop engine
  ralph-bmad.sh       BMAD wrapper with story status tracking
  .gitignore          Standard ignores

Devcontainer updated:
  workspaceFolder  -> <target-dir>
  Rebuild the container to open directly in this project.

Available agents (via /bmad-agent-bmm-<name>):
  pm, architect, sm, dev, qa, ux-designer, analyst, tech-writer

Quick start workflow:
  1. /bmad-agent-bmm-pm     -> Create Product Brief
  2. /bmad-agent-bmm-pm     -> Create PRD
  3. /bmad-agent-bmm-architect -> Create Architecture
  4. /bmad-agent-bmm-sm     -> CS (Create Story with Ralph Tasks)
  5. /bmad-agent-bmm-dev    -> DS (Ralph Dev Story - autonomous)
  6. /bmad-agent-bmm-dev    -> CR (Code Review)
  7. /bmad-agent-bmm-qa     -> QA (Ralph QA Automate)

Ralph workflow triggers:
  DS  = Dev Story (Ralph loop, DEFAULT)
  DSC = Dev Story Classic (original)
  QA  = QA Automate (Ralph loop, DEFAULT)
  QAC = QA Classic (original)
  RUX = Ralph UX Story
```

## Error Handling

- If the installer fails, show the error output and suggest checking Node.js version (`node -v`) and that `BMAD-METHOD/` has its dependencies (`npm install` in BMAD-METHOD)
- If git init fails, the project may already be a git repo — that's fine, continue
- If the initial commit fails (e.g., pre-commit hooks), report but don't block — the project is still usable
- If `gh auth status` fails, tell the user to run `gh auth login` first and stop
- If `gh repo create` fails (e.g., repo already exists, permission denied), show the error and ask the user to resolve it — do not proceed with the submodule step without a valid remote
- If `git submodule add` fails, the most likely cause is a naming conflict in `.gitmodules` — show the error and suggest checking for stale submodule entries
