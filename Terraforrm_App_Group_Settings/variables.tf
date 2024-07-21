variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
}

variable "host_pool_name" {
  description = "The name of the virtual desktop host pool"
  type        = string
}

variable "preferred_app_group_type" {
  description = "The preferred app group type (Desktop or RemoteApp)"
  type        = string
}

variable "host_pool_type" {
  description = "The type of the host pool (Pooled or Personal)"
  type        = string
}

variable "load_balancer_type" {
  description = "The load balancer type (BreadthFirst or DepthFirst)"
  type        = string
}

variable "maximum_sessions_allowed" {
  description = "The maximum number of sessions allowed per user"
  type        = number
}
