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



# module "vm" {
#   source  = "terraform-google-modules/vm/google"
#   version = "7.8.0"
#   project_id  = "tempterraformproject"
# # project

#   labels = {
#     project     = "terraform-practice",
#     environment = "dev"
#     component = "GCP-module-learning"
#   }
# }

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name          = "${random_id.bucket_prefix.hex}-bucket-tfstate"
  force_destroy = false
  location      = "ASIA"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}