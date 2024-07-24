variable "region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-1"
}

variable "organization" {
  type        = string
  description = "The HCP terraform organisation"
  default     = "Gnomesoft"
}

variable "project" {
  type        = string
  description = "The HCP terraform project"
  default     = "demo-project"
}

variable "aws_profile" {
  type        = string
  description = "The profile we are connecting to the target AWS with for our workspaces"
}

variable "account_aliases" {
  type        = map(string)
  description = "The account Ids we want to create workspaces for"
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
    accounts       = list(string)
    run_after      = optional(list(string), [])
    disabled       = optional(bool, false)
  }))
}

variable "force_delete_workspace" {
  type        = bool
  description = "Allow terraform to force delete the workspace - this is useful when working with sandbox accounts"
  default     = false
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with AWS"
}
