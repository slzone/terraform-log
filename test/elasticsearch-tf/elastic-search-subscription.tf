resource "kubernetes_manifest" "subscription_openshift_operators_redhat_elasticsearch_operator" {
  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind" = "Subscription"
    "metadata" = {
      "name" = "elasticsearch-operator"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {
      "channel" = "stable-5.2"
      "name" = "elasticsearch-operator"
      "source" = "redhat-operators"
      "sourceNamespace" = "openshift-marketplace"
    }
  }
}
