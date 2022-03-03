##################################################################################
# This file contains variables for configuration of Logging 
##################################################################################

##################################################################################
# General Configuration
##################################################################################

variable "vpc_zone_names" {
  #type    = list(string)
  type = map
  default = { }
}

# variable "vpc_subnet_ids" {
#   type        = list(string)
#   description = "Subnet IDs"
# }

variable "worker_count" {
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


variable "prefix" {
  description = "Prefix to name all the provisioned resources."

  validation {
    condition     = length(var.prefix) >= 4 && length(var.prefix) <= 30
    error_message = "The prefix length has to be between 4 and 30 characters."
  }
}