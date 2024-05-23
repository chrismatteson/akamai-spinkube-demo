output project_name {
    value = local.ProjectName
}

output root_pass {
  value = random_uuid.root_pass.id
}

output ip_addresses {
    value = local.ip_addresses
}

output clusters {
  value = var.edge_regions
}