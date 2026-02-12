# Devcontainer Troubleshooting

## Common Issues

### Platform mismatch (Apple Silicon / ARM)

**Symptom**: Build fails or binaries crash on Apple Silicon Macs.

**Fix**: Ensure both build and run use `--platform=linux/amd64`:
```json
"build": { "options": ["--platform=linux/amd64"] },
"runArgs": ["--platform=linux/amd64"]
```

Also ensure Dockerfile binary downloads use `amd64` arch explicitly (e.g., kubectl).

### Docker socket permission denied

**Symptom**: `permission denied while trying to connect to the Docker daemon socket`

**Fix**: Add docker group and user membership in Dockerfile:
```dockerfile
RUN groupadd -f docker && usermod -aG docker vscode
```

### Mount not found / empty

**Symptom**: Mounted directories are empty or mount fails.

**Fixes**:
1. Ensure the source path exists on the host before building
2. For `${localEnv:HOME}` mounts, verify the directory exists: `ls -la ~/.<dir>`
3. Check Docker Desktop file sharing settings include the source path

### postCreateCommand fails

**Symptom**: Container builds but post-create script fails.

**Fixes**:
1. Ensure script has correct shebang: `#!/usr/bin/env bash`
2. Ensure script is executable or called with `bash .devcontainer/post-create.sh`
3. Check script doesn't depend on tools installed after it runs
4. Use `set -euo pipefail` to catch errors early

### Workspace folder not writable

**Symptom**: Cannot create/edit files in the workspace.

**Fix**: Ensure `remoteUser` and `containerUser` match the owner of the workspace directory. Default convention uses `vscode` user.

### Extension not loading

**Symptom**: VS Code extensions listed in devcontainer.json don't appear.

**Fix**: Extensions must be under `customizations.vscode.extensions`:
```json
"customizations": {
  "vscode": {
    "extensions": ["extension.id"]
  }
}
```

### Rebuild not picking up changes

**Symptom**: Changes to Dockerfile or devcontainer.json not reflected.

**Fix**: Use "Dev Containers: Rebuild Without Cache" from the command palette.

## Debugging Workflow

1. Check build logs: Command Palette → "Dev Containers: Show Container Log"
2. Check running container: `docker ps` and `docker logs <id>`
3. Shell into container: `docker exec -it <id> bash`
4. Validate devcontainer.json: ensure valid JSON (no trailing commas)
5. Test Dockerfile standalone: `docker build -f .devcontainer/Dockerfile .devcontainer/`
