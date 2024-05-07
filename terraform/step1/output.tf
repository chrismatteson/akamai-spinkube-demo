output "kubeconfig" {
  value = module.kubeedge.kubeconfig
  sensitive = true
}

output "api_endpoints" {
  value = module.kubeedge.api_endpoints
}

output "ProjectName" {
  value = local.ProjectName
}

output "tags" {
  value = local.tags
}