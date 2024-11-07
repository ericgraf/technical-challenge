variable "region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_name" {
  type    = string
  default = "k8s-prod"
}

variable "CF_API_TOKEN" {
  type = string
  sensitive = true
}

variable "CF_API_EMAIL" {
  type = string
  sensitive = true
}
