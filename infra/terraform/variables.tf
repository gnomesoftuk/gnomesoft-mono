variable "organization" {
  default = "Gnomesoft"
}

variable "project" {
  default = "demo-project"
}

variable "vcs" {
  type = object({
    org   = string
    trunk = string
  })
}

variable "workspaces" {
  type = map(any)
}

variable "defaults" {
  type = map(string)
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with AWS"
}
