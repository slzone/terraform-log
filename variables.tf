##################################################################################
# This file contains variables for configuration of Logging 
##################################################################################

##################################################################################
# General Configuration
##################################################################################


variable "worker_zones" {
  type    = map
  default = {}
}

variable "worker_nodes_per_zone" {
  type = number
  default = 1
}

variable "entitlement" {
  description = "Name of entittlement, use for openshift cluster"
  type        = string
  default     = null
}

variable "taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  description = "Set taints to worker nodes."
  default     = null
}
  
variable "ibmcloud_api_key" {
    type = string
    sensitive = true
}
variable "region" {
  description = "Region to provision the Openshift cluster. List all available regions with: ibmcloud regions"
}

variable "resource_group" {
  description = "Resource Group id in your account to host the cluster. List all available resource groups with: ibmcloud resource groups. It is created if empty"
}

variable "resource_group_id" {
    type = string
}

variable "labels" {
  type    = map
  default = {}
}


variable "schematics" {
  type    = bool
  default = true
  description = "Set to false if you are not running this template in schematics"
}


##################################################################################
# Logging Configuration
##################################################################################

variable "log_flavor" {
  type        = string
  default     = "mx2.4x32" 
  description = "Flavor or machine type of the logging nodes. Memory must be at least 32 GB. List all flavors for each zone with: 'ibmcloud ks flavors --zone us-east-1'. Examples: 'mx2.4x32', 'mx2.8x64'"
}


##################################################################################
# Info about the OpenShift cluster logging will be installed into
##################################################################################

variable "cluster_name" {
  type			= string
  description	= "Cluster name."
}


variable "worker_pool_name" {
  type			= string
  description	= "pool name."
}

variable "vpc_id" {
  type			= string
  description	= "VPC ID."
}


variable "node_select" {
  type = string
  default = ""
}

variable "enable_monitoring" {
  type = bool
  default = true
}
