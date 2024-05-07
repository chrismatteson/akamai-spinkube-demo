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

locals {
  kubeconfig     = data.terraform_remote_state.step1.outputs.kubeconfig
  yamlkubeconfig = yamldecode(local.kubeconfig)
  ProjectName    = data.terraform_remote_state.step1.outputs.ProjectName
  tags           = data.terraform_remote_state.step1.outputs.tags
  node_ips       = [for node in data.kubernetes_nodes.nodes.nodes : node.status.0.addresses.1.address]
}

provider "helm" {
  kubernetes {
    host = data.terraform_remote_state.step1.outputs.api_endpoints[0]

    token             = local.yamlkubeconfig.users[0].user.token
    insecure = true
  #  cluster_ca_certificate = local.yamlkubeconfig.clusters[0].cluster.certificate-authority-data
  }
}

provider "kubernetes" {
  host = data.terraform_remote_state.step1.outputs.api_endpoints[0]

  token             = local.yamlkubeconfig.users[0].user.token
  insecure = true
#  cluster_ca_certificate = local.yamlkubeconfig.clusters[0].cluster.certificate-authority-data
}

data "kubernetes_nodes" "nodes" {}

resource "helm_release" "cloudcore" {
  name  = "cloudcore"
  chart = "./charts/cloudcore"
  namespace = "kubeedge"

  values = [
    "${file("./charts/cloudcore/values.yaml")}"
  ]

  set {
    name = "cloudCore.modules.cloudHub.advertiseAddress[0]"
    value = local.node_ips[0]
  }
}

resource "helm_release" "spinkube" {
  name  = "spinkube"
  chart = "./charts/spinkube"
}

