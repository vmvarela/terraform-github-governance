# Actions Runner Scale Sets Example

This example demonstrates how to integrate Kubernetes-based Actions Runner Scale Sets with runner groups.

## Prerequisites

- Kubernetes cluster (with kubectl configured)
- Helm 3.x installed
- GitHub organization with appropriate plan
- GitHub token or GitHub App credentials

## What This Example Creates

1. **Runner Groups with Scale Sets**:
   - `production-runners`: Scale set with 2-10 runners in `arc-prod` namespace
   - `development-runners`: Scale set with 1-5 runners in `arc-dev` namespace

2. **Actions Runner Controller**:
   - Deployed in `arc-systems` namespace
   - Manages all scale sets in the cluster

3. **Repositories**:
   - `backend-api`: Production application
   - `frontend-app`: Frontend application
   - `dev-tooling`: Development tools

## Usage

### 1. Configure GitHub Credentials

Choose one authentication method:

**Option A: GitHub Token**
```bash
export TF_VAR_github_token="ghp_your_token_here"
```

**Option B: GitHub App**
```bash
export TF_VAR_github_app_id=123456
export TF_VAR_github_app_installation_id=789012
export TF_VAR_github_app_private_key="$(cat path/to/private-key.pem)"
```

### 2. Configure Kubernetes Access

Ensure your kubectl is configured to access your cluster:

```bash
kubectl cluster-info
```

### 3. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

### 4. Verify Deployment

Check that the controller and scale sets are running:

```bash
# Check controller
kubectl get pods -n arc-systems

# Check scale sets
kubectl get pods -n arc-prod
kubectl get pods -n arc-dev

# Check runners in GitHub
# Go to: https://github.com/organizations/YOUR_ORG/settings/actions/runner-groups
```

## Configuration Options

### Scale Set Settings

Each runner group can have an optional `scale_set` configuration:

```hcl
runner_groups = {
  "my-runners" = {
    visibility = "selected"
    repositories = ["repo1", "repo2"]

    scale_set = {
      namespace        = "arc-my-runners"    # Kubernetes namespace (default: "arc-runners")
      create_namespace = true                # Create namespace if not exists (default: true)
      version          = "0.13.0"           # Chart version (default: "0.13.0")
      min_runners      = 1                  # Minimum runners (default: 1)
      max_runners      = 5                  # Maximum runners (default: 5)
      runner_image     = "ghcr.io/actions/actions-runner:latest"  # Runner image
      pull_always      = true               # Always pull image (default: true)
      container_mode   = "dind"             # "dind" or "kubernetes" (default: "dind")
    }
  }
}
```

### Private Container Registry

If using custom runner images from a private registry:

```hcl
actions_runner_controller = {
  github_token              = var.github_token
  private_registry          = "myregistry.io"
  private_registry_username = "myuser"
  private_registry_password = var.registry_password
}

runner_groups = {
  "custom-runners" = {
    scale_set = {
      runner_image = "myregistry.io/my-runner:latest"
    }
  }
}
```

### Container Modes

**Docker-in-Docker (dind)**:
```hcl
scale_set = {
  container_mode = "dind"
}
```
- Runs Docker daemon inside runner pod
- Full Docker capabilities
- Higher resource usage

**Kubernetes Mode**:
```hcl
scale_set = {
  container_mode = "kubernetes"
}
```
- Uses Kubernetes for container workloads
- More efficient resource usage
- Requires Kubernetes-compatible workflows

## Cleanup

```bash
terraform destroy
```

This will:
1. Remove scale sets from Kubernetes
2. Remove Actions Runner Controller
3. Delete runner groups from GitHub
4. Archive repositories (if configured)

## Notes

- Runner groups are created first by the main module
- Scale sets reference existing runner groups (they don't create them)
- The controller must be deployed before scale sets
- Each scale set runs in its own Kubernetes namespace
- Runners automatically register with GitHub when pods start

## Troubleshooting

### Runners not appearing in GitHub

Check scale set logs:
```bash
kubectl logs -n arc-prod -l app.kubernetes.io/component=runner-scale-set
```

### Controller issues

Check controller logs:
```bash
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller
```

### Authentication errors

Verify credentials are correctly set:
```bash
# For token auth
kubectl get secret arc-github-creds -n arc-prod -o jsonpath='{.data.github_token}' | base64 -d

# For GitHub App auth
kubectl get secret arc-github-creds -n arc-prod -o jsonpath='{.data.github_app_id}' | base64 -d
```

## Additional Resources

- [Actions Runner Controller Documentation](https://github.com/actions/actions-runner-controller)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
