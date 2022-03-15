resource "kubernetes_manifest" "namespace_openshift_logging" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "annotations" = {
        "openshift.io/node-selector" = ""
      }
      "labels" = {
        "openshift.io/cluster-monitoring" = "true"
      }
      "name" = "openshift-logging"
    }
  }
}
