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

data "terraform_remote_state" "step1" {
  backend = "local"

  config = {
    path = "../step1/terraform.tfstate"
  }
}

data "terraform_remote_state" "step2" {
  backend = "local"

  config = {
    path = "../step2/terraform.tfstate"
  }
}

locals {
  kubeconfig     = data.terraform_remote_state.step1.outputs.kubeconfig
  yamlkubeconfig = yamldecode(local.kubeconfig)
  ProjectName    = data.terraform_remote_state.step1.outputs.ProjectName
  tags           = data.terraform_remote_state.step1.outputs.tags
  cloudcore_ip = data.terraform_remote_state.step2.outputs.cloudcore_ip

}

provider "kubernetes" {
  host = data.terraform_remote_state.step1.outputs.api_endpoints[0]

  token             = local.yamlkubeconfig.users[0].user.token
  insecure = true
#  cluster_ca_certificate = local.yamlkubeconfig.clusters[0].cluster.certificate-authority-data
}
   

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "kubernetes_secret" "token" {
  metadata {
    name = "tokensecret"
    namespace = "kubeedge"
  }
}

resource "random_uuid" "root_pass" {
}

resource "linode_instance" "follower" {
  for_each = toset(var.edge_regions)
  label    = "${local.ProjectName}-${each.key}-instance"
  image    = "linode/debian12"
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

resource "null_resource" "null" {
  for_each = toset(var.edge_regions) 

  connection {
    host        = linode_instance.follower[each.key].ip_address
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
      "apt-get install -y wget containerd runc apt-transport-https ca-certificates curl gpg",
      "mkdir -p /etc/containerd",
      "wget https://github.com/containernetworking/plugins/releases/download/v1.4.1/cni-plugins-linux-amd64-v1.4.1.tgz",
      "mkdir -p /opt/cni/bin",
      "tar Czxvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.1.tgz",
      "mkdir -p /etc/cni/net.d/",
      "wget https://raw.githubusercontent.com/chrismatteson/akamai-spinkube-demo/main/spinkube-kubeedge/step3/bridge.conf",
      "mv bridge.conf /etc/cni/net.d/bridge.conf",
      "containerd config default > /etc/containerd/config.toml",
      "systemctl restart containerd",
      "wget https://github.com/kubeedge/kubeedge/releases/download/v${var.kubeedge_version}/keadm-v${var.kubeedge_version}-linux-${var.kubeedge_arch}64.tar.gz",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "apt-get update",
      "apt-get install -y kubelet kubeadm kubectl",
      "apt-mark hold kubelet kubeadm kubectl",
      "sudo systemctl enable --now kubelet",
      "tar -zxvf keadm-v${var.kubeedge_version}-linux-${var.kubeedge_arch}64.tar.gz",
      "cp keadm-v${var.kubeedge_version}-linux-${var.kubeedge_arch}64/keadm/keadm /usr/local/bin/keadm",
      "keadm join --cloudcore-ipport='${local.cloudcore_ip}:10000' --edgenode-name=${linode_instance.follower[each.key].label} --token=${data.kubernetes_secret.token.data.tokendata} --kubeedge-version=v1.17.0"
    ]
  }
}

resource "kubernetes_manifest" "join" {
  for_each = null_resource.null
  manifest = {
    "kind": "Node",
    "apiVersion": "v1",
    "metadata": {
      "name": "${linode_instance.follower[each.key].label}",
      "labels": {
        "name": "${linode_instance.follower[each.key].label}",
        "node-role.kubernetes.io/edge": ""
      }
    }
  }
}

