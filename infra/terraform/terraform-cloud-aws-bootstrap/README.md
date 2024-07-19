# Workspace bootstrap

To bootstrap a new workspace do the following:

- Add a new workspace entry to the workspaces.auto.tfvars file

# Bootstrapping trust between a TFC workspace and AWS

This directory contains example code for setting up a Terraform Cloud workspace whose runs will be automatically authenticated to AWS using Workload Identity.

The aws-federation module sets up OIDC on one AWS account

The aws-tf-workspace module creates an IAM role for each workspace and
configures the Terraform Cloud workspace

## How to use

You'll need the Terraform CLI and AWS CLI installed, and you'll need to set the following environment variables in your local shell:

1. `TFE_TOKEN`: a Terraform Cloud user token with permission to create workspaces within your organization.

You'll also need to authenticate the AWS provider as you would normally using one of the methods mentioned in the AWS provider documentation [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

Run `terraform plan` to verify your setup, and then run `terraform apply`.

Congratulations! You now have a Terraform Cloud workspace where runs will automatically authenticate to AWS when using the AWS Terraform provider.

## Limitations

* The aws-federation module assumes that everything is deployed into ONE AWS account. Hence
it will not work for a multi-account setup (yet)

* If deploying to a sandbox environment the state will be out of date
when the env is destroyed. You will have to manually remove some parts of
the state to achieve a successful run.

`terraform state rm module.aws-federation.aws_iam_openid_connect_provider.tfc_provider`