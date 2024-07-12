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
  type = map(object({
    auto_apply     = bool
    vcs_repository = optional(string)
    working_dir    = optional(string, "/infra/terraform")
  }))
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with AWS"
}
