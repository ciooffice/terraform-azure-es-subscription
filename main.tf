# Configure the Azure provider
terraform {
  required_version = ">= 0.12.24"
  required_providers {
    azurerm = "~> 2"
    azuread = {
      source  = "hashicorp/azuread"
      version = "=1.4.0"
    }
  }
}

data "azurerm_client_config" "current" {}

# Create Azure Subscription
resource "azurerm_subscription" "main" {
  subscription_id   = var.subscription_id
  subscription_name = var.subscription_name
  billing_scope_id  = var.billing_scope_id

  tags              = var.subscription_tags

  # lifecycle {
  #   ignore_changes = [
  #     tags,
  #   ]
  # }
}

# Register resource providers
resource "null_resource" "azurerm_providers" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 60;
      az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID;
      %{ for provider in var.resource_providers ~}
      az provider register --namespace ${provider} --subscription ${azurerm_subscription.main.subscription_id};
      %{ endfor ~}
      sleep 180;
    EOT
  }
  depends_on = [azurerm_subscription.main]
  triggers = {
    version            = 1
    resource_providers = join(", ", var.resource_providers)
  }
}

# Read owner user account
data "azuread_user" "owner" {
  for_each            = toset(var.owner_users)

  user_principal_name = each.key
}

# Add Owner permissions
resource "azurerm_role_assignment" "owner" {
  for_each             = data.azuread_user.owner

  scope                = "/subscriptions/${azurerm_subscription.main.subscription_id}"
  role_definition_name = "Owner"
  principal_id         = data.azuread_user.owner[each.key].id
}

data "azurerm_management_group" "main" {
  name = "${var.root_id}-${var.landing_zone_key}"
}

resource "azurerm_management_group_subscription_association" "main" {
  management_group_id = data.azurerm_management_group.main.id
  subscription_id     = azurerm_subscription.main.id
}

# Assign Lighthouse management
# resource "azurerm_lighthouse_assignment" "main" {
#   scope                    = "/subscriptions/${azurerm_subscription.main.subscription_id}"
#   lighthouse_definition_id = var.lighthouse_definition_id
#   depends_on               = [null_resource.azurerm_providers]
# }


