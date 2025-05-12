terraform {
  backend "s3" {
    bucket         = "guysi-bucket"                        # Your S3 bucket name
    key            = "devstack/instance/terraform.tfstate" # Path to the state file in the bucket
    region         = "us-east-1"                           # Your S3 bucket region
    encrypt        = true                                  # Recommended
    # dynamodb_table = "terraform-lock-table"             # Optional for locking
  }
}

provider "openstack" {
  cloud = "devstack-admin" # The cloud name from your clouds.yaml
}

# Data source to get the Fedora image ID (to create the boot volume from)
data "openstack_images_image_v2" "fedora_image_for_volume" {
  name        = "Fedora-Cloud-Base-37-1.7.x86_64" # Image to use for the boot volume
  most_recent = true
}

# Data source to get the flavor ID
data "openstack_compute_flavor_v2" "m1_small" {
  name = "m1.small"                             # Flavor used by guysi-fedora
}

# Data source for the private network
data "openstack_networking_network_v2" "my_private_network" {
  name = "my-private-network"                                  # Network used by guysi-fedora
}

# Explicitly define the network port for the instance
resource "openstack_networking_port_v2" "instance_port" {
  name               = "port-for-terraform-clone"
  network_id         = data.openstack_networking_network_v2.my_private_network.id
  admin_state_up     = true # Ensures the port is administratively up
  security_group_ids = [ # Apply security groups directly to the port
    data.openstack_networking_secgroup_v2.default_sg.id,
    data.openstack_networking_secgroup_v2.my_ssh_sg.id,
    data.openstack_networking_secgroup_v2.icmp_sg.id
  ]
  
  fixed_ip {
    subnet_id = "aa6198ee-e6d3-409f-abfa-977a94ead115" # Your provided subnet ID
  }

  # CORRECTED extra_dhcp_option syntax
  # This argument expects a list of maps.
  extra_dhcp_option {
    name       = "6" # DHCP option code for DNS servers
    value      = "8.8.8.8"
    ip_version = 4 # Explicitly setting to 4, though it's often the default
  }
  # If you wanted to add a secondary DNS server, you would add another extra_dhcp_option block:
  # extra_dhcp_option {
  #   name       = "6"
  #   value      = "8.8.4.4" 
  #   ip_version = 4
  # }
}

# Data sources for existing security groups (to get their IDs)
data "openstack_networking_secgroup_v2" "default_sg" {
  name      = "default"
  tenant_id = data.openstack_networking_network_v2.my_private_network.tenant_id
}
data "openstack_networking_secgroup_v2" "my_ssh_sg" {
  name = "my-ssh"
  # If 'my-ssh' is not unique across tenants, add:
  # tenant_id = data.openstack_networking_network_v2.my_private_network.tenant_id
}
data "openstack_networking_secgroup_v2" "icmp_sg" {
  name = "icmp"
  # If 'icmp' is not unique across tenants, add:
  # tenant_id = data.openstack_networking_network_v2.my_private_network.tenant_id
}

# Resource for the Compute Instance
resource "openstack_compute_instance_v2" "demo_instance_clone" {
  name            = "terraform-guysi-fedora-clone"
  flavor_id       = data.openstack_compute_flavor_v2.m1_small.id
  key_pair        = "guysi-test"

  block_device {
    uuid                  = data.openstack_images_image_v2.fedora_image_for_volume.id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
    volume_size           = 20
  }

  network {
    port = openstack_networking_port_v2.instance_port.id # Use the ID of the port created above
  }
}

# Resource for the Floating IP (allocation)
resource "openstack_networking_floatingip_v2" "fip_demo_instance_clone" {
  pool = "public"
}

# Resource to associate the Floating IP with the Instance using compute API
resource "openstack_compute_floatingip_associate_v2" "fip_associate_compute" {
  floating_ip = openstack_networking_floatingip_v2.fip_demo_instance_clone.address
  instance_id = openstack_compute_instance_v2.demo_instance_clone.id
}