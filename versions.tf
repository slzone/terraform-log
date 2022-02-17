
##############################################################################
# Terraform Providers
##############################################################################
# terraform {
#   required_providers {
#     ibm = {
#       source = "IBM-Cloud/ibm"
#       version = ">= 1.36.0"
#     }
#   }
# }

# terraform {
#   required_version = ">=0.13"
#   required_providers {
#     ibm = {
#       source = "IBM-Cloud/ibm"
#     }
#   }
# }

terraform {
  required_version = ">=0.13"
  # required_providers {
  #   ibm = {
  #     source = "IBM-Cloud/ibm"
  #   }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = ">=1.8.1"
    # }
  }
}

# provider "ibm" {
#     ibmcloud_api_key = var.ibmcloud_api_key
#     ibmcloud_timeout   = 120
# }

provider "kubernetes" {
   alias = "logcluster"
   version = ">=1.8.1"
   host                   = data.ibm_container_cluster_config.cluster.host
   client_certificate     = data.ibm_container_cluster_config.cluster.admin_certificate
   client_key             = data.ibm_container_cluster_config.cluster.admin_key
   cluster_ca_certificate = data.ibm_container_cluster_config.cluster.ca_certificate
}
