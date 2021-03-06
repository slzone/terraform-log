resource "kubernetes_manifest" "operatorgroup_my_grafana_operator_my_grafana_operator" {
  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind" = "OperatorGroup"
    "metadata" = {
      "name" = "my-grafana-operator"
      "namespace" = "my-grafana-operator"
    }
    "spec" = {
      "targetNamespaces" = [
        "my-grafana-operator",
      ]
    }
  }
}

resource "kubernetes_manifest" "subscription_my_grafana_operator_my_grafana_operator" {
  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind" = "Subscription"
    "metadata" = {
      "name" = "my-grafana-operator"
      "namespace" = "my-grafana-operator"
    }
    "spec" = {
      "channel" = "v4"
      "name" = "grafana-operator"
      "source" = "community-operators"
      "sourceNamespace" = "openshift-marketplace"
    }
  }
}
