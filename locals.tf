locals {
  mgmt_resource_group        = "rg-${var.root_id}-mgmt"
}

locals {
  sub_to_mgmtgroup_map = {
    teca-managed   = [for sub in module.subscription : sub.subscription_id if sub.landing_zone_key == "teca-managed"]
    teca-auto      = [for sub in module.subscription : sub.subscription_id if sub.landing_zone_key == "teca-auto"]
    online-managed = [for sub in module.subscription : sub.subscription_id if sub.landing_zone_key == "online-managed"]
    online-auto    = [for sub in module.subscription : sub.subscription_id if sub.landing_zone_key == "online-auto"]
    corp-managed   = [for sub in module.subscription : sub.subscription_id if sub.landing_zone_key == "corp-managed"]
    corp-auto      = [for sub in module.subscription : sub.subscription_id if sub.landing_zone_key == "corp-auto"]
    sandboxes      = [for sub in module.subscription : sub.subscription_id if sub.landing_zone_key == "sandboxes"]
  }
}

locals {
  sub_to_vnet_map         = { for ip_range, sub_key in var.ip_plan : sub_key => ip_range if sub_key != "" }
  spoke_subnets_ip_ranges = concat(var.identity_vnet_address_space, values(local.sub_to_vnet_map))
}

locals {
  log_analytics_workspace = values(module.enterprise_scale.azurerm_log_analytics_workspace.management)[0]
  log_analytics_solutions = ["ADAssessment"]
}

locals {
  configure_management_resources = {
    settings = {
      log_analytics = {
        enabled = true
        config = {
          retention_in_days                           = var.log_analytics_retention_days
          enable_monitoring_for_arc                   = true
          enable_monitoring_for_vm                    = true
          enable_monitoring_for_vmss                  = true
          enable_solution_for_agent_health_assessment = true
          enable_solution_for_anti_malware            = true
          enable_solution_for_azure_activity          = true
          enable_solution_for_change_tracking         = true
          enable_solution_for_service_map             = true
          enable_solution_for_sql_assessment          = true
          enable_solution_for_updates                 = true
          enable_solution_for_vm_insights             = true
          enable_sentinel                             = true
        }
      }
      security_center = {
        enabled = true
        config = {
          email_security_contact             = var.email_security_contact
          enable_defender_for_acr            = true
          enable_defender_for_app_services   = true
          enable_defender_for_arm            = true
          enable_defender_for_dns            = true
          enable_defender_for_key_vault      = true
          enable_defender_for_kubernetes     = true
          enable_defender_for_servers        = true
          enable_defender_for_sql_servers    = true
          enable_defender_for_sql_server_vms = true
          enable_defender_for_storage        = true
        }
      }
    }
    location = null
    tags     = null
    advanced = {
      resource_suffix = "${local.deployment_hash}"
      custom_settings_by_resource_type = {
        azurerm_resource_group = {
          management = {
            name = local.mgmt_resource_group
          }
        },
        azurerm_log_analytics_workspace = {
          management = {
            tags = {
              "CostCenter" = var.platform_subscriptions.management.cost_center
            }
          }
        },
        azurerm_log_analytics_solution = {
          management = {
            tags = {
              "CostCenter" = var.platform_subscriptions.management.cost_center
            }
          }
        },
        azurerm_automation_account = {
          management = {
            tags = {
              "CostCenter" = var.platform_subscriptions.management.cost_center
            }
          }
        }
      }
    }
  }
}