output "kubeconfig" {
  value = base64decode(linode_lke_cluster.leader.kubeconfig)
  sensitive = true
}

output "private_key" {
  value = chomp(tls_private_key.ssh_key.private_key_openssh)
  sensitive = true
}