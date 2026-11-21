locals {
  infrastructure = {
    project        = "devops-capstone", orchestrator = "kind", cluster_name = "devops-capstone"
    namespace      = "devops-capstone", application_url = "http://localhost:${var.app_port}"
    prometheus_url = "http://localhost:${var.prometheus_port}", grafana_url = "http://localhost:${var.grafana_port}"
    managed_by     = "terraform", generated_by = "terraform-local-provider"
  }
}
resource "local_file" "infrastructure_inventory" {
  filename        = "${path.module}/../reports/infrastructure.json"
  content         = jsonencode(local.infrastructure)
  file_permission = "0644"
}
