resource "kubernetes_manifest" "configmap_openshift_user_workload_monitoring_user_workload_monitoring_config" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "config.yaml" = <<-EOT
      prometheus:
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
      
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name" = "user-workload-monitoring-config"
      "namespace" = "openshift-user-workload-monitoring"
    }
  }
}
