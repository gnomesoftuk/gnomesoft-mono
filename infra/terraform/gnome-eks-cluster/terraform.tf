terraform {
  cloud {
    organization = "Gnomesoft"

    workspaces {
      name = "gnome-eks-cluster"
    }
  }
}