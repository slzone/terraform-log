// Create infrastructure for logging and monitoring

// Create a dedicated worker pool for logging (and eventually monitoring)

#####################################################
# vpc cluster worker-pool configure
# Copyright 2022 IBM
#####################################################



resource "ibm_container_vpc_worker_pool" "pool" {
  cluster           = var.cluster_name
  worker_pool_name  = var.worker_pool_name
  flavor            = var.log_flavor
  vpc_id            = var.vpc_id
  worker_count      = var.worker_nodes_per_zone
  resource_group_id = var.resource_group_id
  labels            = (var.labels != null ? var.labels : null)
  entitlement       = (var.entitlement != null ? var.entitlement : null)

  dynamic zones {
    for_each = (var.worker_zones != null ? var.worker_zones : {})
    content {
      name      = zones.key
      subnet_id = zones.value.subnet_id
    }
  }

  dynamic taints {
    for_each = (var.taints != null ? var.taints : [])
    content {
      key    = taints.value.key
      value  = taints.value.value
      effect = taints.value.effect
    }
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

resource "kubernetes_namespace" "elasticsearch-namespace" {
  provider = kubernetes.logcluster
  metadata {
    name = "openshift-operators-redhat"
    annotations = {
      "openshift.io/node-selector" = var.node_select

    }
    labels = {
      "openshift.io/cluster-monitoring" = var.enable_monitoring
    }
  }
}

// It is not currently possible to create a operator group object and subscription with Terraform so this is being down with a bash script.

resource "null_resource" "elastic-search-operator" {
  
  depends_on = [kubernetes_namespace.elasticsearch-namespace]

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


resource "kubernetes_namespace" "logging-namespace" {
  provider = kubernetes.logcluster

  depends_on = [kubernetes_namespace.elasticsearch-namespace]
  metadata {
    name = "openshift-logging"
    annotations = {
      "openshift.io/node-selector" = var.node_select

    }
    labels = {
      "openshift.io/cluster-monitoring" = var.enable_monitoring
    }
  }
}

resource "null_resource" "cluster-logging-operator" {
  depends_on = [kubernetes_namespace.logging-namespace]

  provisioner "local-exec" {
    

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
    
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/instance.yaml"
        COMMAND
    }
}

resource "kubernetes_namespace" "monitoring-namespace" {
  provider = kubernetes.logcluster
  depends_on = [kubernetes_namespace.elasticsearch-namespace]
  metadata {
    name = "my-grafana-operator"
    annotations = {
      "openshift.io/node-selector" = var.node_select

    }
    labels = {
      "openshift.io/cluster-monitoring" = var.enable_monitoring
    }
  }
}

resource "null_resource" "instantiate-monitoring" {
  
  depends_on = [kubernetes_namespace.monitoring-namespace]
  provisioner "local-exec" {
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/monitoring-config.yml"
            kubectl apply -f "${path.module}/user-workload-monitoring-config.yml"
            kubectl apply -f "${path.module}/grafana-operator.yaml"
        COMMAND
  }
}
