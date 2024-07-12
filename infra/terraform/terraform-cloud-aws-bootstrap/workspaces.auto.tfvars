vcs = {
  org   = "gnomesoftuk"
  trunk = "main"
}

workspaces = {
  learn-terraform-checks = {
    auto_apply = true
  }
  gnome-eks-cluster = {
    auto_apply = true
    vcs_repository = "gnomesoft-mono"
    working_dir = "/infra/terraform/gnome-eks-cluster"
  }
}
