// Create infrastructure for logging and monitoring

// Create a dedicated worker pool for logging (and eventually monitoring)

#####################################################
# vpc cluster worker-pool configure
# Copyright 2022 IBM
####################################################
resource "ibm_container_vpc_worker_pool" "logging_pool" {
  cluster           = var.cluster_name
  worker_pool_name  = "${var.prefix}-logging"
  flavor            = var.log_flavor
  vpc_id            = var.vpc_id
  worker_count      = var.worker_count
  resource_group_id = var.resource_group_id
  labels            = (var.labels != null ? var.labels : null)
  entitlement       = (var.entitlement != null ? var.entitlement : null)

  dynamic zones {
    for_each = var.vpc_zone_names 
    content {
      name      = zones.value
      subnet_id = var.vpc_subnet_ids[zones.key]
    }
  }
}

resource "null_resource" "taint_logging_pool" {
    depends_on = [ibm_container_vpc_worker_pool.logging_pool]

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]

        command = <<COMMAND
            echo ${ibm_container_vpc_worker_pool.logging_pool.worker_pool_name} ; \
            echo ${ibm_container_vpc_worker_pool.logging_pool.cluster} ; \
            echo ${var.resource_group} ; \
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud oc worker-pool taint set \
                --worker-pool ${ibm_container_vpc_worker_pool.logging_pool.worker_pool_name} \
                --cluster ${ibm_container_vpc_worker_pool.logging_pool.cluster} \
                --taint logging-monitoring=node:NoExecute -f -q
        COMMAND

    }
}

data "ibm_container_cluster_config" "cluster" {
  resource_group_id = var.resource_group_id
  cluster_name_id   = var.cluster_name
  admin             = true
  config_dir        = var.schematics == true ? "/tmp/.schematics" : "."
}


//
// The install and configuration of the elasticsearch and cluster logging operators is based on the
// CLI documentation found here: https://docs.openshift.com/container-platform/4.6/logging/cluster-logging-deploying.html
//
// There are three steps to installing logging:
//     1. Install ElasticSearch Operator
//     2. Install Cluster Logging Operator
//     3. Create an instance of the Cluster Logging Operator
//

// 1. Install ElasticSearch Operator involves 
    //Create a namespace for the OpenShift Elasticsearch Operator.
    //Install the OpenShift Elasticsearch Operator by creating the following objects:
        //Create an Operator Group object.
        //Create a Subscription object.

resource "null_resource" "elasticsearch-namespace" {
  depends_on = [null_resource.taint_logging_pool]

  provisioner "local-exec" {
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/elastic-search-namespace.yaml"
        COMMAND
        }
}

// It is not currently possible to create a operator group object and subscription with Terraform so this is being down with a bash script.

resource "null_resource" "elastic-search-operator" {
  
  depends_on = [null_resource.elasticsearch-namespace]

  provisioner "local-exec" {
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/elastic-search-operator.yaml"
        COMMAND
        }
}

resource "null_resource" "elastic-search-subscription" {
  
  depends_on = [null_resource.elastic-search-operator]

  provisioner "local-exec" {
    #when    = destroy
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/elastic-search-subscription.yaml"
        COMMAND

  }
}

// 2. Install Cluster Logging Operator involves 
    //Create a namespace for the OpenShift Elasticsearch Operator.
    //Install the Cluster Logging Operator by creating the following objects:
        //Create an Operator Group object.
        //Create a Subscription object.


resource "null_resource" "logging-namespace" {
  depends_on = [null_resource.elastic-search-subscription]

  provisioner "local-exec" {
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/logging-namespace.yaml"
        COMMAND
        }
}

resource "null_resource" "cluster-logging-operator" {
  depends_on = [null_resource.logging-namespace]

  provisioner "local-exec" {
    #when    = destroy
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/cluster-logging-operator.yaml"
        COMMAND

  }
}

resource "null_resource" "cluster-logging-subscription" {
  depends_on = [null_resource.cluster-logging-operator]
  provisioner "local-exec" {
    #when    = destroy
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/cluster-logging-subscription.yaml"
        COMMAND

  }
}

// 3. Create a Cluster Logging instance
//
// This uses the instantce.yaml script to provide the logging parameters
// It is not currently possible to create a logging instace with Terraform so this is being down with a bash script.

resource "time_sleep" "wait_10_minutes" {
  depends_on = [null_resource.cluster-logging-subscription]

  create_duration = "10m"
}

resource "null_resource" "instantiate_cluster_logging" {
  
  depends_on = [time_sleep.wait_10_minutes]
  provisioner "local-exec" {
   # when    = destroy
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/instance.yaml"
        COMMAND
    }
}


resource "null_resource" "monitoring-namespace" {
  depends_on = [null_resource.elasticsearch-namespace]

  provisioner "local-exec" {
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/monitoring-namespace.yaml"
        COMMAND
        }
}


resource "null_resource" "instantiate-monitoring" {
  
  depends_on = [null_resource.monitoring-namespace]
  provisioner "local-exec" {
   # when    = destroy
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/monitoring-config.yml"
            kubectl apply -f "${path.module}/user-workload-monitoring-config.yml"
            kubectl apply -f "${path.module}/grafana-operator.yaml"
        COMMAND
  }
}

