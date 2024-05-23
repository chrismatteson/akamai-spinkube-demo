terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      # version = "..."
    }
  }
}

provider "linode" {
}

resource "random_id" "project_name" {
  byte_length = 4
}

locals {
  ProjectName = var.project_name == "" ? random_id.project_name.hex : var.project_name
  tags = concat(
    var.tags,
    [
      var.project_name == "" ? random_id.project_name.hex : var.project_name
    ],
  )
  ip_addresses = [ for ip in linode_instance.k3d : ip.ip_address ]
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_uuid" "root_pass" {
}

resource "linode_instance" "k3d" {
  for_each = toset(var.edge_regions)
  label    = "${local.ProjectName}-${each.key}-instance"
  image    = "linode/debian11"
  authorized_keys = [
    chomp(tls_private_key.ssh_key.public_key_openssh)
  ]
  region    = each.key
  type      = "g6-edge-dedicated-2"
  root_pass = random_uuid.root_pass.id

  tags = local.tags

  interface {
    purpose = "public"
  }
}

resource "local_file" "private_key" {
  content = tls_private_key.ssh_key.private_key_openssh
  filename = "${path.module}/private.key"
  file_permission = "0400"
}

resource "null_resource" "create" {
  for_each = toset(var.edge_regions) 

  connection {
    host        = linode_instance.k3d[each.key].ip_address
    type        = "ssh"
    user        = "root"
    agent       = "false"
    private_key = chomp(tls_private_key.ssh_key.private_key_openssh)
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "systemctl stop apparmor",
      "systemctl disable apparmor",
      "apt-get install -y wget curl",
      "wget wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sh ./get-docker.sh",
      "k3d cluster create wasm-cluster --image ghcr.io/spinkube/containerd-shim-spin/k3d:v0.14.1 --port \"8081:80@loadbalancer\" --agents 2 --api-port \"${linode_instance.k3d[each.key].ip_address}:55555\"",
      "k3d kubeconfig get -a > /${each.key}-kubeconfig"
    ]
  }

  provisioner "local-exec" {
    command = "scp -o \"StrictHostKeyChecking no\" -i ${local_file.private_key.filename} root@${linode_instance.k3d[each.key].ip_address}:/${each.key}-kubeconfig . && KUBECONFIG=./${each.key}-kubeconfig helm install spinkube ../../charts/spinkube"
  }
}

resource "null_resource" "destroy" {
  for_each = toset(var.edge_regions) 

  provisioner "local-exec" {
    when    = destroy
    command = "if [ -f ${each.key}-kubeconfig ]; then rm ${each.key}-kubeconfig; fi"
  }
}


