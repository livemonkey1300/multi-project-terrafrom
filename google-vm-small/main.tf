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



resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = var.tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.vm_image.self_link
    }
  }

  network_interface {
    network = var.network

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "terraform:${file("~/.ssh/id_rsa.pub")}"
  }

  labels = {
    environment = "dev"
    project     = "multi-project-terraform"
  }
}