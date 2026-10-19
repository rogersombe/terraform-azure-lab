data "azurerm_subscription" "primary" {
  subscription_id = var.subscription_id
}

# Look up the built-in Owner role
data "azurerm_role_definition" "owner" {
  name  = "Owner"
  scope = data.azurerm_subscription.primary.id
}

# The rules for using Owner: one hour max, a reason is required,
# and someone else has to approve
resource "azurerm_role_management_policy" "owner_rules" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = data.azurerm_role_definition.owner.id

  activation_rules {
    maximum_duration      = "PT1H"
    require_justification = true
    require_approval      = true

    approval_stage {
      primary_approver {
        object_id = var.approver_object_id
        type      = "User"
      }
    }
  }
}

# Rog may ask for Owner. He does not hold it until it is approved.
resource "azurerm_pim_eligible_role_assignment" "rog_owner" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = data.azurerm_role_definition.owner.id
  principal_id       = var.requester_object_id
  justification      = "P3 lab: Owner on request instead of permanently"

  schedule {
    expiration {
      duration_days = 30
    }
  }

  depends_on = [azurerm_role_management_policy.owner_rules]
}