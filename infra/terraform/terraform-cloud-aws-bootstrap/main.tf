provider "aws" {
  region = "us-east-1"
}

provider "tfe" {
  hostname = var.tfc_hostname
}

module "aws-federation" {
  source = "./modules/aws-federation"
}

module "tf_workspace" {
  source   = "./modules/aws-tf-workspace"
  for_each = var.workspaces

  tfc_organization_name       = var.organization
  tfc_project_name            = var.project
  tfc_workspace_name          = each.key
  aws_oidc_provider_tfc       = module.aws-federation.aws_oidc_provider_tfc
  aws_oidc_client_id_list_tfc = module.aws-federation.aws_oidc_client_id_list_tfc
  vcs_org                     = var.vcs.org
  vcs_repository              = coalesce(each.value["vcs_repository"], each.key)
  vcs_branch                  = var.vcs.trunk
  vcs_trigger_patterns        = ["${each.value.working_dir}/**/*"]
  working_dir                 = each.value.working_dir
  auto_apply                  = each.value.auto_apply
}