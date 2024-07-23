vcs = {
  org   = "gnomesoftuk"
  trunk = "main"
}

account_aliases = { 
  cloudguru = "975050282187"
}

workspaces = {
  gnome-workload-vpc = {
    auto_apply = true
    vcs_repository = "gnomesoft-mono"
    working_dir = "/infra/terraform/gnome-workload-vpc"
    accounts = ["cloudguru"]
  }
 gnome-ecs-cluster = {
    auto_apply = false // disabled for now
    vcs_repository = "gnomesoft-mono"
    working_dir = "/infra/terraform/gnome-ecs-cluster"
    accounts = ["cloudguru"]
  }
  gnome-eks-cluster = {
    auto_apply = false // disabled for now
    vcs_repository = "gnomesoft-mono"
    working_dir = "/infra/terraform/gnome-eks-cluster"
    accounts = ["cloudguru"]
  }
  gnome-app-wordpress = {
    auto_apply = true
    vcs_repository = "gnomesoft-mono"
    working_dir = "/infra/terraform/gnome-app-wordpress"
    accounts = ["cloudguru"]
  }
}
