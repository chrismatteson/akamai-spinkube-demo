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

resource "linode_lke_cluster" "lke" {
    label       = "${local.ProjectName}-SpinKube"
    k8s_version = "1.29"
    region      = var.region
    tags        = local.tags

    pool {
        type  = "g6-standard-2"
        count = 1
    }
}

