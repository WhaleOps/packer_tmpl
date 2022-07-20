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

variable "debug" {
  type    = string
  default = "false"
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

# t2.micro it is under the AWS free-tier
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

locals {
  ami_name = "Apache-DolphinScheduler"
}

source "amazon-ebs" "dolphinscheduler" {
  ami_name      = "${local.ami_name}-V${var.dolphinscheduler_version}"
  instance_type = "${var.instance_type}"
  region        = "${var.region}"
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
    source      = "systemd/dolphinscheduler-standalone.service"
    destination = "/tmp/dolphinscheduler-standalone.service"
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
      "DEBUG=${var.debug}",
    ]
    script = "scripts/dolphinscheduler_builder.sh"
  }
}

