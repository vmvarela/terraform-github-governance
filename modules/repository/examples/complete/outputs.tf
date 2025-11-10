# Outputs
output "production_api" {
  description = "Production API repository details"
  value = {
    name     = module.production_api.name
    html_url = module.production_api.html_url
    ssh_url  = module.production_api.ssh_clone_url
  }
}

output "library" {
  description = "Open source library repository details"
  value = {
    name     = module.open_source_library.name
    html_url = module.open_source_library.html_url
  }
}

output "template" {
  description = "Template repository details"
  value = {
    name     = module.service_template.name
    html_url = module.service_template.html_url
  }
}
