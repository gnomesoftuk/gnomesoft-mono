vcs = {
  org   = "gnomesoftuk"
  trunk = "main"
}

account_aliases = {
  cloudguru = "637423456632"
}

// where workspaces are dependent, list them in order
// they will be deployed
workspaces = {
  gnome-workload-vpc = {
    auto_apply     = true
    vcs_repository = "gnomesoft-mono"
    working_dir    = "/infra/terraform/gnome-workload-vpc"
    accounts       = ["cloudguru"]
  }
  gnome-ecs-cluster = {
    auto_apply     = true
    vcs_repository = "gnomesoft-mono"
    working_dir    = "/infra/terraform/gnome-ecs-cluster"
    accounts       = ["cloudguru"]
    run_after      = ["gnome-workload-vpc"]
  }
  gnome-eks-cluster = {
    auto_apply     = false // disabled for now
    vcs_repository = "gnomesoft-mono"
    working_dir    = "/infra/terraform/gnome-eks-cluster"
    accounts       = ["cloudguru"]
    disabled       = true
  }
  gnome-app-wordpress = {
    auto_apply     = true
    vcs_repository = "gnomesoft-mono"
    working_dir    = "/infra/terraform/gnome-app-wordpress"
    accounts       = ["cloudguru"]
    run_after      = ["gnome-ecs-cluster"]
  }
}
