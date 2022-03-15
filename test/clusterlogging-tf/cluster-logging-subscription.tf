resource "kubernetes_manifest" "subscription_openshift_logging_cluster_logging" {
  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind" = "Subscription"
    "metadata" = {
      "name" = "cluster-logging"
      "namespace" = "openshift-logging"
    }
    "spec" = {
      "channel" = "stable-5.2"
      "name" = "cluster-logging"
      "source" = "redhat-operators"
      "sourceNamespace" = "openshift-marketplace"
    }
  }
}
