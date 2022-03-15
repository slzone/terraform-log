resource "kubernetes_manifest" "namespace_my_grafana_operator" {
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
      "name" = "my-grafana-operator"
    }
  }
}
