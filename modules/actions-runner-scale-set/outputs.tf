# Main module outputs
output "scale_set" {
  description = "The Helm release of the runner scale set."
  value       = keys(helm_release.scale_set)
}

output "controller" {
  description = "The Helm release of the controller."
  value       = helm_release.controller[0].name
}
