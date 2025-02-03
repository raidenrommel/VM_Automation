provider "google" {
  project     = "<PROJECT_ID>"
  region      = "<REGION>"
  credentials = file("<CREDENTIALS_PATH>")
}

resource "google_compute_instance" "voltes_vm" {
  name         = "<VM_NAME>"
  machine_type = "<MACHINE_TYPE>"
  zone         = "<ZONE>"

  boot_disk {
    initialize_params {
      image = "<IMAGE>"
    }
  }

  network_interface {
    network = "<NETWORK>"
    access_config {}
  }

  service_account {
    email  = "<SERVICE_ACCOUNT_EMAIL>"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_storage_bucket" "functions_bucket" {
  name     = "<BUCKET_NAME>"
  location = "<BUCKET_LOCATION>"
}

resource "google_storage_bucket_object" "stop_vm_zip" {
  name   = "stop_vm.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = "<STOP_VM_SOURCE_PATH>"
}

resource "google_storage_bucket_object" "start_vm_zip" {
  name   = "start_vm.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = "<START_VM_SOURCE_PATH>"
}

resource "google_cloudfunctions_function" "stop_vm" {
  name        = "stop-vm-function"
  description = "Function to stop the VM"
  runtime     = "<RUNTIME>"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.stop_vm_zip.name
  trigger_http          = true
  entry_point           = "stop_vm"
  https_trigger_security_level = "SECURE_ALWAYS"
}

resource "google_cloudfunctions_function" "start_vm" {
  name        = "start-vm-function"
  description = "Function to start the VM"
  runtime     = "<RUNTIME>"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.start_vm_zip.name
  trigger_http          = true
  entry_point           = "start_vm"
  https_trigger_security_level = "SECURE_ALWAYS"
}

resource "google_cloud_scheduler_job" "stop_vm" {
  name        = "stop-vm-job"
  description = "Stop VM every Saturday at 4:00 PM"
  schedule    = "0 16 * * 6"
  time_zone   = "<TIME_ZONE>"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.stop_vm.https_trigger_url
    oidc_token {
      service_account_email = "<SERVICE_ACCOUNT_EMAIL>"
    }
  }
}

resource "google_cloud_scheduler_job" "start_vm" {
  name        = "start-vm-job"
  description = "Start VM every Sunday at 4:00 PM"
  schedule    = "0 16 * * 0"
  time_zone   = "<TIME_ZONE>"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.start_vm.https_trigger_url
    oidc_token {
      service_account_email = "<SERVICE_ACCOUNT_EMAIL>"
    }
  }
}

output "stop_vm_url" {
  value = google_cloudfunctions_function.stop_vm.https_trigger_url
}

output "start_vm_url" {
  value = google_cloudfunctions_function.start_vm.https_trigger_url
}

