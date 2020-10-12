# Terraform Components: AWS Demo Virtual Machine

This is a simple module which can be included to add a simple Ubuntu 20.04 Virtual Machine with
no customization, and is purely there to expose an "endpoint" inside the network.

## Role: Create a Virtual Machine, security group and potentially add a public IP address to it.

This role creates:

1. An Ubuntu 20.04 Virtual Machine, attached to a pre-created Subnet.
2. A security group, permitting inbound ICMP Ping, SSH, HTTP and HTTPS, and all outbound traffic.

Optionally, this role can also create a public Elastic IP which is assigned to the network
interface of the virtual machine.

## Variables

* Defined in `_General.tf`.
  * `Project_Prefix`: This is the name associated to all resources created. Default: `demo`.
* Defined in `Virtual Machine.tf`
  * `Hostname_Suffix`: The suffix to add to the created appliance, and is added after the
  `Project_Prefix` string. For example, if `demo` is the `Project_Prefix`, the hostname would be
  `demovm01` given the default `Hostname_Suffix`. Default: `vm01`.
  * `Key_Name`: The name of the SSH Key to be provided from the AWS APIs. Left blank creates the
  virtual machine with no SSH key authentication. Default: `null`.
  * `Subnet_ID`: The ID of the subnet into which the VM should be built.
  * `Public`: Whether to assign a public IP address or not. Default: `false`.

## Outputs
* Defined in `Virtual Machine.tf`
  * `ip`: The public IP address, if assigned, otherwise the private IP address.
  * `name`: The hostname assigned to this appliance.