terraform {
 backend "gcs" {
   bucket  = "795599003eb21bb0-bucket-tfstate"
   prefix  = "terraform/state"
   
 }
}
