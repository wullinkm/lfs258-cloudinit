terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.44.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "lfs258" {
  name       = "lfs258-${var.cluster_name}"
  public_key = file(var.ssh_public_key_file)
}

resource "hcloud_server" "control_plane" {

  name        = "cp"
  server_type = "cpx21"
  image       = var.image
  location    = var.datacenter
  ssh_keys    = [hcloud_ssh_key.lfs258.id]
  user_data   = file("./cloudinit.yaml")
}

resource "hcloud_server" "worker" {
  name        = "worker"
  server_type = "cpx21"
  image       = var.image
  location    = var.datacenter
  ssh_keys    = [hcloud_ssh_key.lfs258.id]
  user_data   = file("./cloudinit.yaml")
}


resource "hcloud_firewall_attachment" "fw_ref" {
  firewall_id = hcloud_firewall.firewall.id
  server_ids  = hcloud_server.control_plane.*.id
}

resource "hcloud_firewall_attachment" "fw_worker_ref" {
  firewall_id = hcloud_firewall.firewall.id
  server_ids  = hcloud_server.worker.*.id
}

resource "hcloud_firewall" "firewall" {
  name = var.cluster_name

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = formatlist("%s/32", hcloud_server.control_plane.*.ipv4_address)
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = formatlist("%s/32", hcloud_server.control_plane.*.ipv4_address)
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = formatlist("%s/32", hcloud_server.control_plane.*.ipv4_address)
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = formatlist("%s/32", hcloud_server.worker.*.ipv4_address)
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = formatlist("%s/32", hcloud_server.worker.*.ipv4_address)
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = formatlist("%s/32", hcloud_server.worker.*.ipv4_address)
  }

}

output "ssh_commands" {
  value = templatefile("hosts_ssh.tmpl",
    {
      hostnames = hcloud_server.control_plane.*.name,
      hostips   = hcloud_server.control_plane.*.ipv4_address,

      workers   = hcloud_server.worker.*.name,
      workerips = hcloud_server.worker.*.ipv4_address,

      ssh_username = var.ssh_username
    }
  )
}
