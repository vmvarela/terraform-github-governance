#!/bin/bash

set -e

echo "🚀 Setting up Terraform GitHub Governance development environment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
  x86_64)
    ARCH_SUFFIX="amd64"
    ;;
  aarch64|arm64)
    ARCH_SUFFIX="arm64"
    ;;
  *)
    echo "⚠️  Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo -e "${BLUE}🖥️  Detected architecture: $ARCH ($ARCH_SUFFIX)${NC}"

# Install terraform-docs
echo -e "${BLUE}📦 Installing terraform-docs...${NC}"
TERRAFORM_DOCS_VERSION="v0.19.0"
curl -sSLo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-${ARCH_SUFFIX}.tar.gz
tar -xzf terraform-docs.tar.gz terraform-docs
sudo mv terraform-docs /usr/local/bin/
rm terraform-docs.tar.gz
sudo chmod +x /usr/local/bin/terraform-docs

# Install pre-commit
echo -e "${BLUE}📦 Installing pre-commit...${NC}"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y pipx > /dev/null 2>&1
pipx ensurepath
pipx install pre-commit

# Add pipx bin to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# Install tflint plugins (if .tflint.hcl exists)
if [ -f .tflint.hcl ]; then
  echo -e "${BLUE}🔧 Installing tflint plugins...${NC}"
  tflint --init
fi

# Initialize pre-commit hooks
echo -e "${BLUE}🪝 Installing pre-commit hooks...${NC}"
~/.local/bin/pre-commit install
~/.local/bin/pre-commit install --hook-type commit-msg

# Initialize Terraform
echo -e "${BLUE}🏗️  Initializing Terraform...${NC}"
terraform init > /dev/null 2>&1 || echo "⚠️  Terraform init failed (might need provider configuration)"

# Install oh-my-zsh plugins
echo -e "${BLUE}🎨 Configuring oh-my-zsh...${NC}"
cat >> ~/.zshrc << 'EOF'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'
alias tfo='terraform output'
alias tfw='terraform workspace'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# GitHub CLI aliases
alias ghpr='gh pr create'
alias ghprl='gh pr list'
alias ghprv='gh pr view'

# Pre-commit aliases
alias pc='pre-commit run --all-files'
alias pcu='pre-commit autoupdate'

# Terraform-docs
alias tfdoc='terraform-docs markdown table --output-file README.md .'

# Convenience
alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'

EOF

# Create workspace info
echo -e "${BLUE}📋 Workspace information:${NC}"
echo "  Terraform: $(terraform version | head -n1)"
echo "  TFLint: $(tflint --version)"
echo "  terraform-docs: $(terraform-docs version)"
echo "  GitHub CLI: $(gh version | head -n1)"
echo "  pre-commit: $(~/.local/bin/pre-commit --version)"

echo -e "${GREEN}✅ Development environment setup complete!${NC}"
echo ""
echo -e "${BLUE}💡 Useful commands:${NC}"
echo "  tf validate    - Validate Terraform configuration"
echo "  tf test        - Run Terraform tests"
echo "  tff           - Format all Terraform files"
echo "  pc            - Run pre-commit on all files"
echo "  tfdoc         - Update documentation"
echo "  gh pr create  - Create a pull request"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"
