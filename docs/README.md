# Documentation Index

Welcome to the Terraform GitHub Governance module documentation!

## 📚 Getting Started

Start here if you're new to the module:

1. **[Main README](../README.md)** - Module overview, quick start, and examples
2. **[SECURITY.md](../SECURITY.md)** - Security policy and authentication setup
3. **[Quick Start Examples](../examples/)** - Working code examples

## 🔐 Security & Operations

Essential guides for production deployment:

- **[SECURITY.md](../SECURITY.md)** 🔒
  - GitHub App authentication setup (recommended)
  - Personal Access Token (PAT) setup
  - Secret management best practices
  - State file security
  - Audit logging
  - Incident response procedures

- **[TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** 🔧
  - Authentication issues
  - Permission errors
  - State management problems
  - Resource creation failures
  - Performance optimization
  - Import and migration
  - Debug mode

## 📖 Feature Documentation

Detailed guides for specific features:

- **[NEW_FEATURES.md](NEW_FEATURES.md)** ⭐
  - Security Managers
  - Custom Properties (Enterprise Cloud)
  - Workflow Permissions
  - Organization Roles
  - Migration guides

- **[USER_OPTIMIZATION.md](USER_OPTIMIZATION.md)** 🚀
  - Global user permission optimization
  - Automatic team creation
  - Performance benefits
  - Technical implementation
  - Troubleshooting

- **[ORGANIZATION_ROLES.md](ORGANIZATION_ROLES.md)** 👥
  - Organization-wide custom roles
  - Role assignments (users and teams)
  - Repository-level vs org-level roles
  - Examples and best practices

## 🏗️ Architecture & Design

Understand how the module is built:

- **[REFACTORING_ORGANIZATION.md](REFACTORING_ORGANIZATION.md)** 📁
  - File structure explanation
  - Organization-exclusive resources
  - Dual-mode resources
  - Code organization rationale

- **[Architecture Decision Records (ADRs)](adr/)** 🎯
  - [ADR-001: Repository Integration vs Submodule](adr/001-repository-integration-vs-submodule.md)
  - [ADR-002: Dual Mode Pattern](adr/002-dual-mode-pattern.md)
  - [ADR-003: Settings Cascade Priority](adr/003-settings-cascade-priority.md)

## 📊 Performance & Scale

Optimize for large deployments:

- **[PERFORMANCE.md](PERFORMANCE.md)** ⚡
  - Workspace segmentation strategies
  - API rate limit management
  - State optimization techniques
  - Parallel execution best practices
  - Resource limits and recommendations
  - Large-scale deployment patterns

## 🐛 Debugging & Support

When things go wrong:

- **[ERROR_CODES.md](ERROR_CODES.md)** 🚨
  - Complete error code reference (TF-GH-001 through TF-GH-999)
  - Detailed solutions and workarounds
  - Quick reference table
  - Common issues and fixes

- **[TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** 🔍
  - Step-by-step debugging procedures
  - Common error messages
  - Import and migration help
  - Performance troubleshooting

## 📝 Project Information

Release notes and history:

- **[CHANGELOG.md](../CHANGELOG.md)** 📅
  - Version history
  - Release notes
  - Breaking changes
  - Upgrade guides
  - Follows Conventional Commits

- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** ✅
  - Feature implementation status
  - Provider version requirements
  - Known limitations
  - Future roadmap

## 💡 Examples

Practical code examples:

### Basic Examples
- **[Simple](../examples/simple/)** - Minimal configuration
- **[Complete](../examples/complete/)** - Full-featured setup

### Advanced Examples
- **[Rulesets Advanced](../examples/rulesets-advanced/)** - Complex branch protection
- **[Large Scale](../examples/large-scale/)** - 100+ repositories
- **[Migration from Manual](../examples/advanced/migration-from-manual/)** - IaC migration
- **[Disaster Recovery](../examples/advanced/disaster-recovery/)** - Backup and restore
- **[Multi-Region](../examples/advanced/multi-region/)** - GitHub Enterprise setup

## 🤝 Contributing

Want to contribute?

- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Contribution guidelines
- **[GitHub Issues](https://github.com/vmvarela/terraform-github-governance/issues)** - Bug reports and features
- **[GitHub Discussions](https://github.com/vmvarela/terraform-github-governance/discussions)** - Q&A and ideas

## 📖 External Resources

Additional reading:

### Terraform
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Module Best Practices](https://www.terraform.io/docs/language/modules/develop/index.html)
- [Terraform Testing](https://www.terraform.io/language/modules/testing)

### GitHub
- [GitHub REST API](https://docs.github.com/en/rest)
- [GitHub Apps](https://docs.github.com/en/developers/apps)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GitHub Security](https://docs.github.com/en/code-security)

### Provider
- [GitHub Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [GitHub Provider GitHub Repository](https://github.com/integrations/terraform-provider-github)

## 🗺️ Documentation Map

Visual guide to documentation structure:

```
terraform-github-governance/
├── README.md                          # Start here!
├── SECURITY.md                        # 🔒 Security & auth
├── TROUBLESHOOTING.md                 # 🔧 Debugging
├── CHANGELOG.md                       # 📝 Version history
├── CONTRIBUTING.md                    # 🤝 How to contribute
│
├── docs/                              # 📚 Detailed documentation
│   ├── README.md                      # This file
│   │
│   ├── NEW_FEATURES.md               # ⭐ Latest features
│   ├── USER_OPTIMIZATION.md          # 🚀 Performance features
│   ├── ORGANIZATION_ROLES.md         # 👥 Role management
│   ├── REFACTORING_ORGANIZATION.md   # 📁 File structure
│   │
│   ├── PERFORMANCE.md                # ⚡ Optimization guide
│   ├── ERROR_CODES.md                # 🚨 Error reference
│   ├── IMPLEMENTATION_SUMMARY.md     # ✅ Status & roadmap
│   │
│   ├── USER_OPTIMIZATION_IMPLEMENTATION.md  # 🔬 Technical deep-dive
│   │
│   └── adr/                          # 🎯 Architecture decisions
│       ├── 001-repository-integration-vs-submodule.md
│       ├── 002-dual-mode-pattern.md
│       └── 003-settings-cascade-priority.md
│
└── examples/                          # 💡 Code examples
    ├── simple/                        # Basic setup
    ├── complete/                      # Full-featured
    ├── rulesets-advanced/             # Advanced rules
    ├── large-scale/                   # 100+ repos
    └── advanced/                      # Expert patterns
        ├── migration-from-manual/
        ├── disaster-recovery/
        └── multi-region/
```

## 📊 Documentation Statistics

- **Total Documents**: 15+
- **Code Examples**: 7
- **Architecture Decision Records**: 3
- **Error Codes Documented**: 20+
- **Lines of Documentation**: 8,000+
- **Last Updated**: November 12, 2025

## 🏷️ Documentation Tags

Quick navigation by topic:

**By Topic:**
- 🔒 Security: [SECURITY.md](../SECURITY.md)
- 🚀 Performance: [PERFORMANCE.md](PERFORMANCE.md), [USER_OPTIMIZATION.md](USER_OPTIMIZATION.md)
- 🏗️ Architecture: [ADRs](adr/), [REFACTORING_ORGANIZATION.md](REFACTORING_ORGANIZATION.md)
- 🐛 Debugging: [TROUBLESHOOTING.md](../TROUBLESHOOTING.md), [ERROR_CODES.md](ERROR_CODES.md)
- ⭐ Features: [NEW_FEATURES.md](NEW_FEATURES.md), [ORGANIZATION_ROLES.md](ORGANIZATION_ROLES.md)

**By Audience:**
- 👤 Beginners: [README](../README.md), [Simple Example](../examples/simple/)
- 👨‍💼 Operators: [SECURITY.md](../SECURITY.md), [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- 👨‍💻 Developers: [ADRs](adr/), [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- 🏢 Architects: [PERFORMANCE.md](PERFORMANCE.md), [Large Scale Example](../examples/large-scale/)

**By Priority:**
- 🔴 Critical: [SECURITY.md](../SECURITY.md), [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- 🟡 Important: [PERFORMANCE.md](PERFORMANCE.md), [ERROR_CODES.md](ERROR_CODES.md)
- 🟢 Helpful: [NEW_FEATURES.md](NEW_FEATURES.md), [USER_OPTIMIZATION.md](USER_OPTIMIZATION.md)

## 💬 Getting Help

Can't find what you need?

1. **Search the documentation** - Use browser search (Ctrl+F / Cmd+F)
2. **Check examples** - See [examples/](../examples/) for working code
3. **Review error codes** - See [ERROR_CODES.md](ERROR_CODES.md) for specific errors
4. **Open an issue** - [GitHub Issues](https://github.com/vmvarela/terraform-github-governance/issues)
5. **Start a discussion** - [GitHub Discussions](https://github.com/vmvarela/terraform-github-governance/discussions)

## 📝 Documentation Contribution

Found an error or want to improve the docs?

1. Fork the repository
2. Make your changes
3. Submit a pull request
4. Follow the [CONTRIBUTING.md](../CONTRIBUTING.md) guidelines

**Documentation standards:**
- Use clear, concise language
- Include code examples
- Add visual diagrams when helpful
- Keep formatting consistent
- Test all code examples

---

**Last Updated**: November 12, 2025
**Version**: 1.0.0
**Maintainer**: [Victor Varela](https://github.com/vmvarela)
