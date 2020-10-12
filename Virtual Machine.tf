## Data
# AMI
data "aws_ami" "ubuntu2004" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu*20.04*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnet" "Subnet" {
  id = var.Subnet_ID
}

data "null_data_source" "resource" {
  inputs = {
    name = "${var.Project_Prefix}${var.Hostname_Suffix}"
  }
}

## Variables
# Naming
variable "Hostname_Suffix" {
  default     = "vm01"
  type        = string
  description = "String is 'Project_Prefix' followed by the suffix, e.g. `demovm01` where `Project_Prefix` is demo."
}

# Access and Licenses
variable "Key_Name" {
  default     = null
  description = "The name of the SSH Key to be provided from the AWS APIs. Left blank creates the virtual machine with no SSH key authentication."
}

# Network location and addressing

variable "Subnet_ID" {
  description = "The ID of the subnet into which the VM should be built"
  validation {
    condition     = can(regex("^subnet-[0-9a-f]+", var.Subnet_ID))
    error_message = "Subnet IDs must match a particular convention."
  }
}

variable "Public" {
  default     = false
  description = "Assign a public IP address or not"

  validation {
    condition     = var.Public == true || var.Public == false
    error_message = "Value must be a boolean."
  }
}

## Resources
resource "aws_instance" "appliance" {
  tags = {
    Name = data.null_data_source.resource.outputs["name"]
  }

  ami           = data.aws_ami.ubuntu2004.id
  instance_type = "t2.nano"
  key_name      = var.Key_Name
  user_data = templatefile(
    "${path.module}/user_data.txt.tmpl",
    {
      hostname = data.null_data_source.resource.outputs["name"]
    }
  )

  network_interface {
    network_interface_id = aws_network_interface.eth0.id
    device_index         = 0
  }
}

resource "aws_network_interface" "eth0" {
  description = "${data.null_data_source.resource.outputs["name"]}-eth0"
  subnet_id   = data.aws_subnet.Subnet.id
}

resource "aws_network_interface_sg_attachment" "eth0" {
  depends_on           = [aws_network_interface.eth0]
  security_group_id    = aws_security_group.allow_in.id
  network_interface_id = aws_network_interface.eth0.id
}

resource "aws_eip" "eth0" {
  count = var.Public ? 1 : 0
  vpc   = true
}

resource "aws_eip_association" "eth0" {
  count                = var.Public ? 1 : 0
  network_interface_id = aws_network_interface.eth0.id
  allocation_id        = aws_eip.eth0[0].id
}

resource "aws_security_group" "allow_in" {
  name        = "${data.null_data_source.resource.outputs["name"]}_allow_in"
  description = "Allow Ingress and Egress traffic"
  vpc_id      = data.aws_subnet.Subnet.vpc_id

  tags = {
    Name = "${data.null_data_source.resource.outputs["name"]}_allow_in"
  }
}

resource "aws_security_group_rule" "ingress_ping" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_in.id
  description       = "Ping from Anywhere"
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_in.id
  description       = "SSH from Anywhere"
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_in.id
  description       = "HTTP from Anywhere"
}

resource "aws_security_group_rule" "ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_in.id
  description       = "HTTPS from Anywhere"
}

resource "aws_security_group_rule" "egress_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_in.id
  description       = "Anything to Anywhere"
}

## Outputs
output "ip" {
  value = var.Public == true ? aws_eip.eth0[0].public_ip : aws_network_interface.eth0.private_ip
}

output "name" {
  value = data.null_data_source.resource.outputs["name"]
}