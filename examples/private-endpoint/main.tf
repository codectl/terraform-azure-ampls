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

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"


  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.19.0.0/16"]

    subnets = {
      sn1 = {
        network_security_group = {}
        address_prefixes       = ["10.19.1.0/24"]
      }
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

module "private_dns" {
  source  = "codectl/pdns/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name

  zones = local.zones
}

module "privatelink" {
  source  = "codectl/pe/azure"
  version = "~> 1.0"

  depends_on = [module.ampls]

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  endpoints = {
    ampls = {
      name      = module.naming.private_endpoint.name
      subnet_id = module.network.subnets.sn1.id

      private_dns_zone_group = {
        private_dns_zone_ids = [
          module.private_dns.private_zones.monitor.id,
          module.private_dns.private_zones.oms.id,
          module.private_dns.private_zones.ods.id,
          module.private_dns.private_zones.agentsvc.id,
          module.private_dns.private_zones.blob.id,
        ]
      }

      private_service_connection = {
        private_connection_resource_id = module.ampls.monitor_private_link_scope.id
        subresource_names              = ["azuremonitor"]
      }
    }
  }
}
