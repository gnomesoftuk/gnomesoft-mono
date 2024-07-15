vcs = {
  org   = "gnomesoftuk"
  trunk = "main"
}

account_aliases = { 
  cloudguru = "058264128883" 
}

workspaces = {
  learn-terraform-checks = {
    auto_apply = true
    accounts = []
  }
  gnome-eks-cluster = {
    auto_apply = true
    vcs_repository = "gnomesoft-mono"
    working_dir = "/infra/terraform/gnome-eks-cluster"
    accounts = ["cloudguru"]
  }
}
