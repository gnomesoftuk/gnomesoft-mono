vcs = {
  org   = "gnomesoftuk"
  trunk = "main"
}

defaults = {
  working_dir = "/infra/terraform"
}

workspaces = {
  learn-terraform-checks = {
    auto_apply = true
  }
}
