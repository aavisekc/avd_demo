
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_desktop_host_pool" "example" {
  name                        = var.host_pool_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  preferred_app_group_type    = var.preferred_app_group_type
  type                        = var.host_pool_type
  load_balancer_type          = var.load_balancer_type
  maximum_sessions_allowed    = var.maximum_sessions_allowed
}
