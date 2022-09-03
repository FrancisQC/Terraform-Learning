terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  #   credentials = file("./creds.json")

  project = "tempterraformproject"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "network" {
  name = "terraform-network"
}
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["web", "dev"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = google_compute_network.network.name
    access_config {
    }
  }
}


# terraform import google_compute_network.network terraform-network