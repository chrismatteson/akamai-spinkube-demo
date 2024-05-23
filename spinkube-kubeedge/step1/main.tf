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
}

resource "linode_lke_cluster" "leader" {
    label       = "${local.ProjectName}-KubeEdge-Leader"
    k8s_version = "1.29"
    region      = var.leader_region
    tags        = local.tags

    pool {
        type  = "g6-standard-2"
        count = 1
    }
}

