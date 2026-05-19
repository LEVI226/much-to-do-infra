terraform {
  backend "gcs" {
    bucket = "much-to-do-tfstate-gcs"
    prefix = "terraform/state"
  }
}
