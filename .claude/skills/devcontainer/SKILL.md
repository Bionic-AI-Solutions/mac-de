---
name: devcontainer
description: Create, modify, troubleshoot, and manage VS Code devcontainer configurations (.devcontainer/ folder). Use when the user needs to (1) create a new devcontainer setup for a project, (2) add or remove toolchains from an existing devcontainer, (3) modify devcontainer.json settings like mounts, extensions, or features, (4) edit the Dockerfile for a devcontainer, (5) troubleshoot devcontainer build or runtime issues, (6) add a post-create script, or any task involving .devcontainer/ files.
---

# Devcontainer

Create and manage VS Code devcontainer configurations with standard conventions.

## Default Conventions

Always apply these unless the user explicitly overrides:

- **Base image**: `mcr.microsoft.com/devcontainers/base:ubuntu`
- **Platform**: `linux/amd64` (both build options and runArgs)
- **User**: `vscode` (both `remoteUser` and `containerUser`)
- **Workspace mount**: `source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind,consistency=cached`
- **Workspace folder**: `/workspaces/${localWorkspaceFolderBasename}`
- **Docker socket**: Always mount `/var/run/docker.sock` for Docker-in-Docker access
- **Kube config**: Mount `${localEnv:HOME}/.kube` to `/home/vscode/.kube`
- **Extensions**: Always include `anthropic.claude-code`
- **Post-create**: Use `bash .devcontainer/post-create.sh`

## Creating a New Devcontainer

Generate three files in `.devcontainer/`:

### 1. devcontainer.json

Use `assets/devcontainer.template.json` as the base structure. Replace `{{PROJECT_NAME}}` with the project name. Add/remove mounts and extensions based on toolchains selected.

### 2. Dockerfile

Use `assets/Dockerfile.template` as the base structure. Build the Dockerfile by:

1. Start with base dependencies (always include)
2. Add toolchain installs in logical order — see `references/toolchains.md` for snippets
3. Add user/group setup (docker group, directory ownership)
4. End with `USER vscode`

Key rules:
- Combine `apt-get update` with installs and clean up with `rm -rf /var/lib/apt/lists/*`
- Use `ARG` for version pinning (e.g., `ARG NODE_MAJOR=22`)
- Place all `RUN` commands before `USER vscode`
- Use `--no-install-recommends` for apt packages

### 3. post-create.sh

Use `assets/post-create.template.sh` as the base. Include:
- Verification checks for mounted configs (kube, etc.)
- Any runtime setup (skill registration, tool configuration)
- Installation verification echoing tool versions

## Modifying an Existing Devcontainer

When modifying, always read the existing files first. Common modifications:

### Adding a toolchain
1. Read `references/toolchains.md` for the appropriate Dockerfile snippet
2. Add the `RUN` block to the Dockerfile before `USER vscode`
3. Add any required mounts to `devcontainer.json`
4. Add version verification to `post-create.sh`

### Adding VS Code extensions
Add extension IDs to `customizations.vscode.extensions` array in `devcontainer.json`.

### Adding mounts
Add mount strings to the `mounts` array. Format:
```
source=<host-path>,target=<container-path>,type=bind,consistency=cached
```

### Adding devcontainer features
Add feature IDs to the `features` object. Example:
```json
"features": {
  "ghcr.io/devcontainers/features/terraform:1": {}
}
```

## Troubleshooting

For build failures, permission issues, mount problems, and other common issues, see `references/troubleshooting.md`.

## Resources

- **references/toolchains.md** — Dockerfile snippets for Node.js, Python/Pydantic, Docker CLI, kubectl, GitHub CLI
- **references/troubleshooting.md** — Common issues and debugging workflow
- **assets/** — Template files for devcontainer.json, Dockerfile, and post-create.sh
