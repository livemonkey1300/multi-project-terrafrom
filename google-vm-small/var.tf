variable "project_id" {
    description = "The GCP project ID"
    type        = string
    default = "dev-ops-275615"
}

variable "region" {
    description = "The GCP region"
    type        = string
    default     = "northamerica-northeast1"
}

variable "zone" {
    description = "The GCP zone"
    type        = string
    default     = "northamerica-northeast1-a"
}

variable "instance_name" {
    description = "Name of the VM instance"
    type        = string
    default     = "small-vm"
}

variable "machine_type" {
    description = "Machine type for the VM"
    type        = string
    default     = "e2-micro"
}

variable "image_family" {
    description = "Image family for the VM"
    type        = string
    default     = "ubuntu-2004-lts"
}

variable "image_project" {
    description = "Project containing the image"
    type        = string
    default     = "ubuntu-os-cloud"
}

variable "network" {
    description = "Network for the VM"
    type        = string
    default     = "default"
}

variable "tags" {
    description = "Network tags for the VM"
    type        = list(string)
    default     = []
}