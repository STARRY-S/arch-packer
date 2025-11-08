packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  working_dir = env("WORKING_DIR")
  default_password = env("DEFAULT_PASSWORD")
  datetime = env("DATETIME")
  debug = env("DEBUG")
}

source "qemu" "image_build" {
  disk_image       = true
  iso_url          = "${var.working_dir}/tmp/Arch-Linux-x86_64-basic.qcow2"
  iso_checksum     = "file:${var.working_dir}/tmp/Arch-Linux-x86_64-basic.qcow2.SHA256"
  output_directory = "${var.working_dir}/output/"
  disk_size        = "40G"
  format           = "qcow2"
  accelerator      = "none"
  ssh_username     = "arch"
  ssh_password     = "arch"
  ssh_timeout      = "5m"
  vm_name          = "archlinux-cloudimg-${var.datetime}.qcow2"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  boot_wait        = "20s"
  vnc_bind_address = "127.0.0.1"
  qemuargs = [
    ["-m", "8192"],
    ["-smp", "4"],
    ["-nographic"],
    ["-display", "none"],
  ]
}

build {
  sources = ["source.qemu.image_build"]

  provisioner "file" {
    source = "../scripts/archlinux/prepare.sh"
    destination = "~/prepare.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "DEFAULT_PASSWORD=${var.default_password}",
      "DEBUG=${var.debug}"
    ]
    inline = [
      "sudo bash ~/prepare.sh && rm ~/prepare.sh",
    ]
  }
}
