variable "region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_name" {
  type    = string
  default = "k8s-prod"
}

variable "kubernetes_version" {
  default = "1.29"
}