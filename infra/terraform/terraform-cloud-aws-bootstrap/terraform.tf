terraform {
  cloud {
    organization = "Gnomesoft"

    workspaces {
      name = "demo-project-aws-bootstrap"
    }
  }
}