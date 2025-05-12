output "instance_name" {
  description = "Name of the deployed instance"
  value       = openstack_compute_instance_v2.demo_instance_clone.name
}

output "instance_private_ip" {
  description = "Private IP address of the instance (from the first network interface)"
  value       = openstack_compute_instance_v2.demo_instance_clone.network[0].fixed_ip_v4
}

output "instance_public_ip" {
  description = "Public Floating IP address of the instance"
  value       = openstack_networking_floatingip_v2.fip_demo_instance_clone.address
}

output "instance_security_groups" {
  description = "Security groups applied to the instance"
  value       = openstack_compute_instance_v2.demo_instance_clone.security_groups
}

output "instance_boot_volume_id" {
  description = "ID of the boot volume attached to the instance"
  # Note: Accessing the volume ID created via block_device requires a bit more nuance
  # if not explicitly created as a separate openstack_blockstorage_volume_v3 resource.
  # For now, we'll acknowledge it's created. If you need the ID,
  # you might need to create the volume as a separate resource.
  # This output is a placeholder to remind of the boot volume.
  value = "Boot volume created via block_device, ID not directly outputted this way. Check OpenStack."
}