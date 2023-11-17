variable "hcloud_token" {
  sensitive = true
}

variable "cluster_name" {
  description = "prefix for cloud resources"
  type        = string
  default     = "dexcloud"
}


variable "ssh_public_key_file" {
  description = "SSH public key file"
  default     = "~/.ssh/id_rsa.pub"
  type        = string
}

variable "ssh_username" {
  description = "SSH user, used only in output"
  default     = "root"
  type        = string
}


variable "datacenter" {
  default = "nbg1"
  type    = string
}

variable "image" {
  default = "ubuntu-20.04"
  type    = string
}

variable "ip_range" {
  default     = "192.168.0.0/16"
  description = "ip range to use for private network"
  type        = string
}

variable "network_zone" {
  default     = "eu-central"
  description = "network zone to use for private network"
  type        = string
}
