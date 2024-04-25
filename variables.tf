variable "compartment_id" {
  description = "Compartment OCID"
  type        = string
}
variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "sa-saopaulo-1"
}
