provider "google" {
  credentials = file("/Users/eldadmwangi/Downloads/gcr-nodejs-react-deploy-854afe03638a.json") # Replace with your service account key path
  region      = var.region
}

resource "google_compute_instance" "app_server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  # Add the project field here
  project      = "gcr-nodejs-react-deploy" # Replace with your actual project ID

  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}" # Using the image family and project
    }
  }

  network_interface {
    network = "default"
    access_config {} # Allows external IP
  }

  # Metadata for SSH keys
  metadata = {
    ssh-keys = "wachiraeldadmwangi:${file("/Users/eldadmwangi/.ssh/my_gcp_key.pub")}"  # Add your SSH key here
  }

  # Provisioner to install Docker and run containers on the VM
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io || { echo 'Docker installation failed'; exit 1; }",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      # Run backend container
      "sudo docker run -d --name backend -p 4000:4000 ${var.backend_image} || { echo 'Failed to start backend container'; exit 1; }",

      # Run client container
      "sudo docker run -d --name client -p 3000:3000 ${var.client_image} || { echo 'Failed to start client container'; exit 1; }",

      # Run database container (MongoDB)
      "sudo docker run -d --name database -p 27017:27017 ${var.database_image} || { echo 'Failed to start database container'; exit 1; }"
    ]

    # Connection details for provisioner
    connection {
      type        = "ssh"
      user        = "wachiraeldadmwangi"
      private_key = file("/Users/eldadmwangi/.ssh/my_gcp_key") # Replace with your private key path
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  # Output IP for Ansible inventory
  provisioner "local-exec" {
    command = "echo '${google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip}' > ../ansible/hosts"
  }
}

output "instance_ip" {
  value = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
}
