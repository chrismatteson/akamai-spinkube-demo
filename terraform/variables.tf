variable "linode_token" {
  default = ""
}

variable "project_name" {
  default = ""
}

variable "tags" {
  default = []
}

variable "regions" {
  default = [
    "eu-west"
    #"us-den-edge-1",
    #"de-ham-edge-1",
    #"za-jnb-edge-1"
  ]
}