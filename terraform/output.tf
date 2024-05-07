output "kubeconfig" {
  value = module.kubeedge.kubeconfig
  sensitive = true
}

output "private_key" {  
  value = module.kubeedge.private_key
  sensitive = true
}