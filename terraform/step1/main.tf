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

module "kubeedge" {
  source = "./modules/kubeedge"
  project_name = local.ProjectName
  tags = local.tags
  leader_region = var.leader_region
}

