packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
  }
}

# Source AMI: Amazon Linux 2023 (x86_64)
source "amazon-ebs" "al2023" {
  profile       = var.aws_profile
  region        = var.aws_region
  instance_type = var.instance_type

  ami_name        = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-HHmm", timestamp())}"
  ami_description = "JMeter ${var.jmeter_version} on Amazon Linux 2023 (+ Corretto 17, Makefile, run-jmeter.sh)"

  associate_public_ip_address = true

  communicator = "ssh"
  ssh_username = "ec2-user" # required for SSH on AL2023


  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.10.20260202.2-kernel-6.1-x86_64"
      architecture        = "x86_64"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["137112412989"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
  }

  tags = { Component = "JMeter" }
}

build {
  name    = "jmeter-ami"
  sources = ["source.amazon-ebs.al2023"]

  # Upload installer script + assets
  provisioner "file" {
    source      = "${path.root}/scripts/install_jmeter.sh"
    destination = "/tmp/install_jmeter.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/run-jmeter.sh"
    destination = "/tmp/run-jmeter.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/Makefile"
    destination = "/tmp/Makefile"
  }

  provisioner "file" {
    source      = "${path.root}/files/test.jmx"
    destination = "/tmp/test.jmx"
  }

  # Execute installer
  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "sudo bash /tmp/install_jmeter.sh ${var.jmeter_version}",
      "sudo mv /tmp/run-jmeter.sh /usr/local/bin/run-jmeter.sh",
      "sudo chmod +x /usr/local/bin/run-jmeter.sh",
      "sudo mkdir -p /opt/jmeter",
      "sudo mv /tmp/Makefile /opt/jmeter/Makefile",
      "sudo mv /tmp/test.jmx /opt/jmeter/test.jmx",
      "sudo chown -R ec2-user:ec2-user /opt/jmeter",
      "echo 'Build complete: JMeter baked into AMI.'"
    ]
  }
}