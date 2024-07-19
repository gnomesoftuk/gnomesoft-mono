# gnome-workload-vpc

A standard VPC configuration for workloads

## Usage

To test plans locally, do the following

1. Find the workspace name in HCP Terraform

2. Run `TF_WORKSPACE=gnome-workload-vpc-<aws_account_id> terraform init`

3. Run `TF_WORKSPACE=gnome-workload-vpc-<aws_account_id> terraform plan`

All deploys must take place in HCP terraform. Remote apply is disabled.