variable "name" {
  description = "Globally unique document bucket name, including account and environment."
  type        = string
}

variable "tags" {
  description = "Ownership and classification tags."
  type        = map(string)
  default     = {}
}
