resource "kubernetes_manifest" "configmap_openshift_monitoring_cluster_monitoring_config" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "config.yaml" = <<-EOT
      enableUserWorkload: true
      prometheusOperator:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      prometheusK8s: 
        retention: 1y
        volumeClaimTemplate:
          spec:
            storageClassName: ibmc-vpc-block-retain-general-purpose
            volumeMode: Filesystem
            resources:
               requests:
                 storage: 100Gi
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      alertmanagerMain:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      kubeStateMetrics:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      openshiftStateMetrics:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      telemeterClient:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      k8sPrometheusAdapter:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      thanosQuerier:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name" = "cluster-monitoring-config"
      "namespace" = "openshift-monitoring"
    }
  }
}
