variable "token" {
  default = ""
}

variable "kubeedge_version" {
  default = "1.17.0"
}

variable "kubeedge_arch" {
  default = "amd"
}

variable "edge_regions" {
  default = [
    "eu-west"
    #"us-den-edge-1",
    #"de-ham-edge-1",
    #"za-jnb-edge-1"
  ]
}