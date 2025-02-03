provider "google" {
  project     = "voltes-446205"
  region      = "asia-southeast1"
  credentials = file("/home/rommel/VmAutomation/voltes-446205-9de609428249.json")
}

resource "google_compute_instance" "voltes_vm" {
  name         = "voltes-vm"
  machine_type = "e2-micro"
  zone         = "asia-southeast1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = "160842532634-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_storage_bucket" "functions_bucket" {
  name     = "voltes-functions-bucket-446205"
  location = "asia-southeast1"
}

resource "google_storage_bucket_object" "stop_vm_zip" {
  name   = "stop_vm.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = "/home/rommel/VmAutomation/stop_vm.zip"
}

resource "google_storage_bucket_object" "start_vm_zip" {
  name   = "start_vm.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = "/home/rommel/VmAutomation/start_vm.zip"
}

resource "google_cloudfunctions_function" "stop_vm" {
  name        = "stop-vm-function"
  description = "Function to stop the VM"
  runtime     = "python310"

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
  runtime     = "python310"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.start_vm_zip.name
  trigger_http          = true
  entry_point           = "start_vm"
  https_trigger_security_level = "SECURE_ALWAYS"
}

resource "google_cloud_scheduler_job" "stop_vm" {
  name        = "stop-vm-job"
  description = "Stop VM every Saturday at 4:00 PM "
  schedule    = "0 16 * * 6"
  time_zone   = "Asia/Manila"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.stop_vm.https_trigger_url
    oidc_token {
      service_account_email = "160842532634-compute@developer.gserviceaccount.com"
    }
  }
}

resource "google_cloud_scheduler_job" "start_vm" {
  name        = "start-vm-job"
  description = "Start VM every Sunday at 4:00 PM"
  schedule    = "0 16 * * 0"
  time_zone   = "Asia/Manila"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.start_vm.https_trigger_url
    oidc_token {
      service_account_email = "160842532634-compute@developer.gserviceaccount.com"
    }
  }
}


output "stop_vm_url" {
  value = google_cloudfunctions_function.stop_vm.https_trigger_url
}

output "start_vm_url" {
  value = google_cloudfunctions_function.start_vm.https_trigger_url
}
