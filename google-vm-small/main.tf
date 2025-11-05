terraform { 
  cloud { 
    
    organization = "gcp-live" 

    workspaces { 
      name = "vm-deployment-1" 
    } 
  }
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.10.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}