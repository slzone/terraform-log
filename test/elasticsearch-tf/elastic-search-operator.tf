resource "kubernetes_manifest" "operatorgroup_openshift_operators_redhat_openshift_operators_redhat" {
  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind" = "OperatorGroup"
    "metadata" = {
      "name" = "openshift-operators-redhat"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {}
  }
}
