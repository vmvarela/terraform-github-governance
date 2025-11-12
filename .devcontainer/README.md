# Development Container

This directory contains the configuration for the VS Code Dev Container, providing a fully configured development environment for the Terraform GitHub Governance module.

## 🚀 Quick Start

### Prerequisites

1. **Docker Desktop** installed and running
   - [Install Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Supports: macOS (Intel & Apple Silicon), Linux, Windows

2. **Visual Studio Code** with Remote - Containers extension
   - [Install VS Code](https://code.visualstudio.com/)
   - Install extension: `ms-vscode-remote.remote-containers`

> **Note:** This dev container supports both **amd64** (Intel/AMD) and **arm64** (Apple Silicon) architectures automatically.

### Using the Dev Container

1. **Open in Container**:
   ```bash
   # Clone the repository
   git clone https://github.com/vmvarela/terraform-github-governance.git
   cd terraform-github-governance

   # Open in VS Code
   code .
   ```

2. **When VS Code opens**, you'll see a notification:
   - "Folder contains a Dev Container configuration file"
   - Click **"Reopen in Container"**

   OR use Command Palette (Ctrl+Shift+P / Cmd+Shift+P):
   - Type: `Remote-Containers: Reopen in Container`

3. **Wait for setup** (first time only, ~3-5 minutes):
   - Container downloads and builds
   - Tools install automatically
   - Post-create script runs

4. **Start coding!** 🎉
   - All tools are pre-installed
   - VS Code extensions are ready
   - Terminal is configured

## 📦 What's Included

### Tools

| Tool | Version | Description | Architecture |
|------|---------|-------------|--------------|
| **Terraform** | latest | Infrastructure as Code | Multi-arch |
| **TFLint** | latest | Terraform linter | Multi-arch |
| **terraform-docs** | v0.19.0 | Documentation generator | amd64 / arm64 |
| **GitHub CLI** | latest | GitHub command line | Multi-arch |
| **pre-commit** | latest | Git hooks framework | Python (any) |
| **Git** | latest | Version control | Multi-arch |
| **Zsh + Oh My Zsh** | latest | Enhanced shell | Multi-arch |

> **Architecture Support:** All tools automatically detect and install the correct binaries for your platform (Intel/AMD64 or Apple Silicon/ARM64).

### VS Code Extensions

Automatically installed:

**Terraform:**
- `hashicorp.terraform` - Official Terraform extension
- `HashiCorp.HCL` - HCL language support

**Git & GitHub:**
- `github.vscode-pull-request-github` - GitHub PR/Issues
- `github.copilot` - AI pair programming
- `github.copilot-chat` - AI chat assistant
- `eamodio.gitlens` - Git supercharged

**Documentation:**
- `yzhang.markdown-all-in-one` - Markdown tools
- `DavidAnson.vscode-markdownlint` - Markdown linting

**Utilities:**
- `redhat.vscode-yaml` - YAML support
- `esbenp.prettier-vscode` - Code formatter
- `streetsidesoftware.code-spell-checker` - Spell checking

### Shell Aliases

Pre-configured convenience aliases:

**Terraform:**
```bash
tf        # terraform
tfi       # terraform init
tfp       # terraform plan
tfa       # terraform apply
tfd       # terraform destroy
tfv       # terraform validate
tff       # terraform fmt -recursive
tfo       # terraform output
tfw       # terraform workspace
```

**Git:**
```bash
gs        # git status
ga        # git add
gc        # git commit
gp        # git push
gl        # git log --oneline --graph --decorate
gd        # git diff
```

**GitHub CLI:**
```bash
ghpr      # gh pr create
ghprl     # gh pr list
ghprv     # gh pr view
```

**Development:**
```bash
pc        # pre-commit run --all-files
pcu       # pre-commit autoupdate
tfdoc     # terraform-docs markdown table --output-file README.md .
```

## 🔧 Configuration Files

### devcontainer.json

Main configuration file:
- Base image: Ubuntu with common utilities
- Features: Terraform, GitHub CLI, Git, Zsh
- Extensions: See list above
- Settings: Editor, formatter, linting
- Mounts: SSH keys, git config, GitHub CLI config

### post-create.sh

Automation script that runs after container creation:
- Installs terraform-docs
- Installs pre-commit
- Configures shell aliases
- Initializes pre-commit hooks
- Initializes Terraform
- Displays version info

## 🎯 Development Workflow

### First Time Setup

1. **Container starts** → Automatic setup runs
2. **Verify tools**:
   ```bash
   terraform version
   tflint --version
   terraform-docs version
   gh version
   pre-commit --version
   ```

3. **Configure GitHub CLI** (if needed):
   ```bash
   gh auth login
   ```

### Daily Workflow

1. **Open VS Code** → Container starts automatically
2. **Make changes** → Auto-format on save
3. **Run validation**:
   ```bash
   tfv           # Validate Terraform
   tff           # Format files
   pc            # Run pre-commit checks
   ```

4. **Run tests**:
   ```bash
   terraform test
   ```

5. **Commit changes**:
   ```bash
   gc -m "feat: add new feature"  # Conventional commits enforced
   ```

### Pre-commit Hooks

Automatically run on `git commit`:
- ✅ Terraform format check
- ✅ Terraform validate
- ✅ TFLint
- ✅ terraform-docs update
- ✅ Trailing whitespace fix
- ✅ End-of-file fixer
- ✅ Conventional commit message check

Run manually:
```bash
pc              # Run on all files
pc --files main.tf  # Run on specific files
```

## 📝 VS Code Settings

### Automatic Features

- **Format on Save**: Enabled for Terraform, Markdown, YAML
- **Trim Trailing Whitespace**: Enabled
- **Insert Final Newline**: Enabled
- **Terraform Validation**: On save

### Keyboard Shortcuts

**Terraform:**
- `Ctrl+Shift+P` → `Terraform: Validate`
- `Ctrl+Shift+P` → `Terraform: Format Document`

**Git:**
- `Ctrl+Shift+G` → Git panel
- `Ctrl+Enter` → Commit changes

**GitHub:**
- `Ctrl+Shift+P` → `GitHub Pull Requests: Create Pull Request`

## 🔒 Credentials & SSH

### Mounted from Host

The container automatically mounts:
- `~/.ssh` → SSH keys for git operations
- `~/.gitconfig` → Git configuration
- `~/.config/gh` → GitHub CLI authentication

### Configure GitHub Authentication

If not already authenticated:
```bash
gh auth login
```

Follow prompts to authenticate with GitHub.

### SSH Keys

Your existing SSH keys are available in the container. Test:
```bash
ssh -T git@github.com
```

## 🐛 Troubleshooting

### Container Won't Start

1. **Check Docker is running**:
   ```bash
   docker ps
   ```

2. **Rebuild container**:
   - Command Palette → `Remote-Containers: Rebuild Container`

3. **Clear Docker cache**:
   ```bash
   docker system prune -a
   ```

### Tools Not Found

1. **Check post-create script ran**:
   ```bash
   cat /tmp/devcontainer-post-create.log
   ```

2. **Re-run post-create**:
   ```bash
   bash .devcontainer/post-create.sh
   ```

3. **Check PATH**:
   ```bash
   echo $PATH
   source ~/.zshrc
   ```

### Pre-commit Not Working

1. **Reinstall hooks**:
   ```bash
   pre-commit uninstall
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

2. **Update hooks**:
   ```bash
   pre-commit autoupdate
   ```

### Extensions Not Installing

1. **Check internet connection** in container:
   ```bash
   curl -I https://marketplace.visualstudio.com
   ```

2. **Manually install**:
   - VS Code → Extensions panel → Search → Install

## 🚀 Performance Tips

### Speed Up Container Start

1. **Keep Docker running** between sessions
2. **Don't rebuild** unless necessary
3. **Use volume caching** (already configured)

### Reduce Resource Usage

Edit `devcontainer.json`:
```json
{
  "runArgs": [
    "--cpus=2",
    "--memory=4g"
  ]
}
```

### Optimize Pre-commit

Run only on changed files (default):
```bash
git commit  # Only runs on staged files
```

Skip for urgent commits (not recommended):
```bash
git commit --no-verify
```

## 📚 Additional Resources

- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container Features](https://containers.dev/features)
- [Terraform in VS Code](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/vscode-extension)
- [GitHub CLI Manual](https://cli.github.com/manual/)

## 🤝 Contributing

Improvements to the dev container configuration are welcome!

1. Test your changes locally
2. Update this README if needed
3. Submit a PR with description

---

**Happy Coding!** 🎉

**Need help?** Open an issue or check [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
