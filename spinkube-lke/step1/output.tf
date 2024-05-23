output "kubeconfig" {
  value = base64decode(linode_lke_cluster.lke.kubeconfig)
  sensitive = true
}

output "api_endpoints" {
  value = linode_lke_cluster.lke.api_endpoints
}

output "ProjectName" {
  value = local.ProjectName
}

output "tags" {
  value = local.tags
}