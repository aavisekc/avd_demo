resource_group_name       = "v-avdhostpool-rg"
location                  = "Central India"
host_pool_name            = "Demo-host-pool"
preferred_app_group_type  = "Desktop" # Change to "RemoteApp" if needed
host_pool_type            = "Pooled"
load_balancer_type        = "BreadthFirst"
maximum_sessions_allowed  = 2
