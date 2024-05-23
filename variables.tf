variable "basename" {
  default     = "uks-cluster-example"
  description = "Basename to use when naming resources created by this configuration."
  type        = string 
}

variable "zone" {
  default     = "de-fra1"
  description = "UpCloud zone for resource provisioning."
  type        = string
}
