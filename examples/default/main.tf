module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "analytics" {
  source  = "codectl/law/azure"
  version = "~> 1.0"

  workspace = {
    name                = module.naming.log_analytics_workspace.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "ampls" {
  source  = "codectl/ampls/azure"
  version = "~> 1.0"

  monitor_private_link_scope = {
    name                = module.naming.monitor_private_link_scope.name_unique
    resource_group_name = module.rg.groups.demo.name
    scoped_services = {
      law = {
        linked_resource_id = module.analytics.workspace.id
      }
    }
  }
}
