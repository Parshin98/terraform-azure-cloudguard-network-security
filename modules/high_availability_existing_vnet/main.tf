      name = module.common.vm_os_sku
      publisher = module.common.publisher
      product = module.common.vm_os_offer
    }
  }
  os_profile {
    computer_name = "${lower(var.cluster_name)}${count.index+1}"
    admin_username = module.common.admin_username
    admin_password = module.common.admin_password
    custom_data = templatefile("${path.module}/cloud-init.sh", {
        installation_type = module.common.installation_type
        allow_upload_download = module.common.allow_upload_download
        os_version = module.common.os_version
        module_name = module.common.module_name
        module_version = module.common.module_version
        template_type = "terraform"
        is_blink = module.common.is_blink
        bootstrap_script64 = base64encode(var.bootstrap_script)
        location = module.common.resource_group_location
        sic_key = var.sic_key
        tenant_id = var.tenant_id
        virtual_network = var.vnet_name
        cluster_name = var.cluster_name
        external_private_addresses = azurerm_network_interface.nic_vip.ip_configuration[1].private_ip_address
        enable_custom_metrics = var.enable_custom_metrics ? "yes" : "no"
        admin_shell = var.admin_shell
        smart_1_cloud_token = count.index == 0 ? var.smart_1_cloud_token_a : var.smart_1_cloud_token_b
        serial_console_password_hash = var.serial_console_password_hash
        maintenance_mode_password_hash = var.maintenance_mode_password_hash
      })
  }
  os_profile_linux_config {
    disable_password_authentication = local.SSH_authentication_type_condition
    dynamic "ssh_keys" {
      for_each = local.SSH_authentication_type_condition ? [
        1] : []
      content {
        path = "/home/notused/.ssh/authorized_keys"
        key_data = var.admin_SSH_key
      }
    }
  }
  boot_diagnostics {
    enabled = module.common.boot_diagnostics
    storage_uri = module.common.boot_diagnostics ? join(",", azurerm_storage_account.vm-boot-diagnostics-storage.*.primary_blob_endpoint) : ""
  }
  tags = merge(lookup(var.tags, "virtual-machine", {}), lookup(var.tags, "all", {}))
}
//********************** Role Assigments **************************//
data "azurerm_role_definition" "virtual_machine_contributor_role_definition" {
  name = "Virtual Machine Contributor"
}
data "azurerm_role_definition" "reader_role_definition" {
  name = "Reader"
}
data "azurerm_client_config" "client_config" {
}
resource "azurerm_role_assignment" "cluster_virtual_machine_contributor_assignment" {
  count = 2
  lifecycle {
    ignore_changes = [
      role_definition_id, principal_id
    ]
  }
  scope = module.common.resource_group_id
  role_definition_id = data.azurerm_role_definition.virtual_machine_contributor_role_definition.id
  principal_id = local.availability_set_condition ? lookup(azurerm_virtual_machine.vm-instance-availability-set[count.index].identity[0], "principal_id") : lookup(azurerm_virtual_machine.vm-instance-availability-zone[count.index].identity[0], "principal_id")
}
resource "azurerm_role_assignment" "cluster_reader_assigment" 
{
  count = 2
  lifecycle {
    ignore_changes = [
      role_definition_id, principal_id
    ]
  }
  scope = module.common.resource_group_id
  role_definition_id = data.azurerm_role_definition.reader_role_definition.id
  principal_id = local.availability_set_condition ? lookup(azurerm_virtual_machine.vm-instance-availability-set[count.index].identity[0], "principal_id") : lookup(azurerm_virtual_machine.vm-instance-availability-zone[count.index].identity[0], "principal_id")
}

//********************** Output Variables **************************//
output "resource_group_name" { value = var.resource_group_name }
output "location" { value = var.location }
output "admin_password" { value = var.admin_password }
output "installation_type" { value = var.installation_type }
output "module_name" { value = local.module_name }
output "module_version" { value = local.module_version }
output "number_of_vm_instances" { value = var.number_of_vm_instances }
output "allow_upload_download" { value = var.allow_upload_download }
output "vm_size" { value = var.vm_size }
output "disk_size" { value = var.disk_size }
output "is_blink" { value = var.is_blink }
output "os_version" { value = var.os_version }
output "vm_os_sku" { value = var.vm_os_sku }
output "vm_os_offer" { value = var.vm_os_offer }
output "authentication_type" { value = var.authentication_type }
output "serial_console_password_hash" { value = var.serial_console_password_hash }
output "maintenance_mode_password_hash" { value = var.maintenance_mode_password_hash }
output "storage_account_additional_ips" { value = var.storage_account_additional_ips }
output "tags" { value = var.tags }
output "public_ips" { value = azurerm_public_ip.vips[*].id }
output "cluster_vip_ip" { value = azurerm_public_ip.cluster-vip.id }
output "public_ip_prefix_id" { value = azurerm_public_ip_prefix.public_ip_prefix[*].id }
output "frontend_subnet_id" { value = data.azurerm_subnet.frontend.id }
output "backend_subnet_id" { value = data.azurerm_subnet.backend.id }
