provider "google" {
  credentials = file("/Users/eldadmwangi/Downloads/gcr-nodejs-react-deploy-854afe03638a.json") # Replace with your service account key path
  project     = var.project_id
  region      = var.region
}

resource "google_compute_instance" "app_server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}" # Using the image family and project
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Include this to give the VM an external IP
    }
  }

  provisioner "local-exec" {
    command = "echo '${google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip}' > ../ansible/hosts"
  }
}

output "instance_ip" {
  value = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
}