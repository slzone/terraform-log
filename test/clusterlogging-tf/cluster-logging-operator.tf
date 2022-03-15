resource "kubernetes_manifest" "operatorgroup_openshift_logging_cluster_logging" {
  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind" = "OperatorGroup"
    "metadata" = {
      "name" = "cluster-logging"
      "namespace" = "openshift-logging"
    }
    "spec" = {
      "targetNamespaces" = [
        "openshift-logging",
      ]
    }
  }
}
