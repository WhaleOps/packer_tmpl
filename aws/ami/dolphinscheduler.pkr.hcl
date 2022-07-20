packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "dolphinscheduler_version" {
  type    = string
  default = "3.0.0-beta-2"
}

locals {
  ami_name = "Apache-DolphinScheduler"
}

source "amazon-ebs" "dolphinscheduler" {
  ami_name      = "${local.ami_name}-${var.dolphinscheduler_version}-1"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "build-dolphinscheduler"
  sources = [
    "source.amazon-ebs.dolphinscheduler"
  ]

  provisioner "file" {
    source      = "systemd/zookeeper.service"
    destination = "/tmp/zookeeper.service"
  }

  provisioner "file" {
    source      = "systemd/dolphinscheduler-alter.service"
    destination = "/tmp/dolphinscheduler-alter.service"
  }

  provisioner "file" {
    source      = "systemd/dolphinscheduler-api.service"
    destination = "/tmp/dolphinscheduler-api.service"
  }

  provisioner "file" {
    source      = "systemd/dolphinscheduler-master.service"
    destination = "/tmp/dolphinscheduler-master.service"
  }

  provisioner "file" {
    source      = "systemd/dolphinscheduler-worker.service"
    destination = "/tmp/dolphinscheduler-worker.service"
  }

  provisioner "shell" {
    environment_vars = [
      "DOLPHINSCHEDULER_VERSION=${var.dolphinscheduler_version}",
    ]
    script = "scripts/dolphinscheduler_builder.sh"
  }
}

