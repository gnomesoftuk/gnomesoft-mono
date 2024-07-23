provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
}

provider "tfe" {
  hostname = var.tfc_hostname
}

module "aws-federation" {
  source = "./modules/aws-federation"
}

module "tf_workspace" {
  source   = "./modules/aws-tf-workspace"
  for_each = tomap({ for workspace in local.workspaces : workspace.name => workspace })

  tfc_organization_name       = var.organization
  tfc_project_name            = var.project
  tfc_workspace_name          = each.key
  aws_tfc_workspace_role      = each.value.alias
  aws_oidc_provider_tfc       = module.aws-federation.aws_oidc_provider_tfc
  aws_oidc_client_id_list_tfc = module.aws-federation.aws_oidc_client_id_list_tfc
  vcs_org                     = var.vcs.org
  vcs_repository              = coalesce(each.value["vcs_repository"], each.key)
  vcs_branch                  = var.vcs.trunk
  vcs_trigger_patterns        = ["${each.value.working_dir}/**/*"]
  working_dir                 = each.value.working_dir
  auto_apply                  = each.value.auto_apply
  force_delete_workspace      = var.force_delete_workspace
  trigger_workspaces          = each.value.run_after
}

locals {
  workspaces = flatten([
    for workspace_name, workspace in var.workspaces : [
      for account in workspace.accounts : {
        name           = "${workspace_name}-${var.account_aliases[account]}"
        alias          = "${workspace_name}"
        vcs_repository = workspace.vcs_repository
        auto_apply     = workspace.auto_apply
        working_dir    = workspace.working_dir
        run_after      = [for ws in workspace.run_after : "${ws}-${var.account_aliases[account]}"]
      } if workspace.disabled == false
    ]
  ])
}
