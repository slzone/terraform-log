// Create infrastructure for logging and monitoring

// Create a dedicated worker pool for logging (and eventually monitoring)

resource "ibm_container_vpc_worker_pool" "logging_pool" {
  provider = kubernetes.kbn

  cluster          = var.cluster_name
  worker_pool_name = "${var.prefix}-logging"
  flavor           = var.log_flavor
  vpc_id           = var.vpc_id
  worker_count     = "1"
  resource_group_id = var.resource_group_id
  dynamic "zones" {
    for_each = (var.vpc_zone_names != null ? var.worker_zones : {})
    content {
      name      = zones.key
      subnet_id = zones.value.subnet_id
    }
  }
}

// Taint the "logging_pool" worker pool so that only logging pods (such as the ElasticSearch server) will
// run run in the "logging_pool". The intention is to keep the logging pods away from production worker
// nodes. 
// It is not currently possible to taint a worker pool with Terraform so this is being down with a bash script.
// The Terraform Slack channel mentioned that in the future it will be possible to Taint directly from Terraform.


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
  resource_group_id = var.cluster_resource_group_id
  cluster_name_id   = var.cluster_name
  admin             = true
  config_dir        = var.schematics == true ? "/tmp/.schematics" : "."
}

# provider "kubernetes" {
#    version = ">=1.8.1"
#    host                   = data.ibm_container_cluster_config.cluster.host
#    client_certificate     = data.ibm_container_cluster_config.cluster.admin_certificate
#    client_key             = data.ibm_container_cluster_config.cluster.admin_key
#    cluster_ca_certificate = data.ibm_container_cluster_config.cluster.ca_certificate
# }

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
  depends_on = [null_resource.elastic-search-subscription]
  #depends_on = [kubernetes_namespace.elasticsearch-namespace]
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


resource "null_resource" "instantiate_cluster_logging" {
  depends_on = [null_resource.cluster-logging-subscription]
  provisioner "local-exec" {
    
    command = <<COMMAND
            ibmcloud login --apikey ${var.ibmcloud_api_key} -r ${var.region} -g ${var.resource_group} --quiet ; \
            ibmcloud ks cluster config --cluster ${var.cluster_name} --admin
            kubectl apply -f "${path.module}/instance.yaml"
        COMMAND
    }
}

resource "kubernetes_namespace" "monitoring-namespace" {
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
