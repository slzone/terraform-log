resource "kubernetes_manifest" "namespace_openshift_operators_redhat" {
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
      "name" = "openshift-operators-redhat"
    }
  }
}
