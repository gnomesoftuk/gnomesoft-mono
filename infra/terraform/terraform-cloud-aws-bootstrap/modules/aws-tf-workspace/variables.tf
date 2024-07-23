# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "tfc_workspace_name" {
  type        = string
  description = "The name of the workspace that you'd like to create and connect to AWS"
}

variable "force_delete_workspace" {
  type = bool
  description = "Allow terraform to force delete the workspace - this is useful when working with sandbox accounts"
  default = false
}

variable "trigger_workspaces" {
  type = list(string)
  description = "A list of workspaces that this workspace depends on"
  default = []
}

variable "tfc_aws_audience" {
  type        = string
  default     = "aws.workload.identity"
  description = "The audience value to use in run identity tokens"
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with AWS"
}

variable "tfc_organization_name" {
  type        = string
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_project_name" {
  type        = string
  description = "The project under which a workspace will be created"
}

variable "aws_oidc_provider_tfc" {
  type        = string
  description = "the oidc provider arn set in in AWS for authenicating TF cloud"
}

variable "aws_tfc_workspace_role" {
  type = string
  validation {
    condition = length(var.aws_tfc_workspace_role) < 38
    error_message = "The role name is too long. The limit is 38 characters."
  }
}

variable "aws_oidc_client_id_list_tfc" {
  type        = list(string)
  description = "The client list set up in the oidc provider in AWS"
}

variable "vcs_org" {
  type = string
}

variable "vcs_repository" {
  type = string
}

variable "vcs_branch" {
  type = string
}

variable "vcs_trigger_patterns" {
  type = list(string)
}

variable "working_dir" {
  type = string
}

variable "auto_apply" {
  type = bool
  default = false
}


