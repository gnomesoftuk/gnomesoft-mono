# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Data source used to grab the project under which a workspace will be created.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/project
data "tfe_project" "tfc_project" {
  name         = var.tfc_project_name
  organization = var.tfc_organization_name
}

# Runs in this workspace will be automatically authenticated
# to AWS with the permissions set in the AWS policy.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace
resource "tfe_workspace" "team_workspace" {
  name         = var.tfc_workspace_name
  organization = var.tfc_organization_name
  project_id   = data.tfe_project.tfc_project.id
  auto_apply   = var.auto_apply

  working_directory = var.working_dir

  trigger_patterns = var.vcs_trigger_patterns
  force_delete     = var.force_delete_workspace
  vcs_repo {
    branch                     = var.vcs_branch
    identifier                 = "${var.vcs_org}/${var.vcs_repository}"
    github_app_installation_id = data.tfe_github_app_installation.ghe_installation.id
  }
  auto_apply_run_trigger = true
}

data "tfe_workspace" "trigger_workspace" {
  for_each    = toset(var.trigger_workspaces)
  name         = each.key
  organization = var.tfc_organization_name
}

resource "tfe_run_trigger" "link_dependent_workspace" {
  for_each    = data.tfe_workspace.trigger_workspace
  workspace_id = tfe_workspace.team_workspace.id
  sourceable_id = each.value.id
}

resource "tfe_workspace_settings" "test-settings" {
  workspace_id   = tfe_workspace.team_workspace.id
  execution_mode = "remote"
}

# The following variables must be set to allow runs
# to authenticate to AWS.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "enable_aws_provider_auth" {
  workspace_id = tfe_workspace.team_workspace.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."
}

resource "tfe_variable" "tfc_aws_role_arn" {
  workspace_id = tfe_workspace.team_workspace.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.tfc_role.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."
}
