terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
    helm = {}
  }
}

resource "random_id" "project_name" {
  byte_length = 6
}

resource "random_uuid" "token" {
}

locals {
  ProjectName = var.project_name == "" ? random_id.project_name.hex : var.project_name
  token = var.token == "" ? random_uuid.token.id : var.token
  tags = concat(
    var.tags,
    [
      var.project_name == "" ? random_id.project_name.hex : var.project_name
    ],
  )
}

resource "linode_lke_cluster" "leader" {
    label       = "${local.ProjectName}-KubeEdge-Leader"
    k8s_version = "1.29"
    region      = "us-central"
    tags        = local.tags

    pool {
        type  = "g6-standard-2"
        count = 3
    }
}

resource "local_file" "kubeconfig" {
  content  = base64decode(linode_lke_cluster.leader.kubeconfig)
  filename = "${path.module}/kubeconfig.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig.yaml"
  }
  debug = local_file.kubeconfig.content == "foo" ? false : false
}

#resource "helm_release" "keadm" {
#  name = "keadm"
#  chart = "./charts/kubeedge"
#}

resource "helm_release" "spinkube" {
  name = "spinkube"
  chart = "./charts/spinkube"

   set {
    name = "externalIP"
    value = "198.58.115.166"
   }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "linode_instance" "follower" {
  for_each = toset(var.regions)
  label  = "${local.ProjectName}-${each.key}-instance"
  image  = "linode/ubuntu24.04"
  authorized_keys = [
    chomp(tls_private_key.ssh_key.public_key_openssh)
  ]
  region = each.key
  type   = "g6-standard-2"
  root_pass = random_uuid.token.id

  tags       = local.tags

  interface {
    purpose = "public"
  }

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
      "apt-get install -y wget containerd runc apt-transport-https ca-certificates curl gpg",
      "wget https://github.com/kubeedge/kubeedge/releases/download/v${var.kubeedge_version}/keadm-v${var.kubeedge_version}-linux-${var.kubeedge_arch}64.tar.gz",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "apt-get update",
      "apt-get install -y kubelet kubeadm kubectl",
      "apt-mark hold kubelet kubeadm kubectl",
      "sudo systemctl enable --now kubelet",
      "tar -zxvf keadm-v${var.kubeedge_version}-linux-${var.kubeedge_arch}64.tar.gz",
      "cp keadm-v${var.kubeedge_version}-linux-${var.kubeedge_arch}64/keadm/keadm /usr/local/bin/keadm",
      #"curl -fsSL https://get.docker.com -o get-docker.sh",
      #"chmod +x get-docker.sh",
      #"./get-docker.sh",
      "keadm join --cloudcore-ipport='198.58.115.166:10000' --token=ZjYxMDg3YjdkN2VhYTNkNGY0MWQ5ZGE0NTE5MGE0NTcxZWU1NTllZTA5N2I4NGEyOTQyNmVkODFjNGYxMjVmMC5leUpoYkdjaU9pSklVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKbGVIQWlPakUzTVRVeE16Z3lOalY5Lm1QMi0tampCQXktSWxISTl0bVhscHRUeEZ6ejlnTWpTN0RfckFMSzNIZGs= --kubeedge-version=v1.17.0"
    ]
  }
}
