# Testing, Security, and Monitoring

Pytest covers every endpoint, the status schema, and metrics exposure. CI uses Semgrep for SAST, Gitleaks for secret detection, Checkov/Trivy/Kubescape for configuration security, Trivy for container vulnerabilities, Kubeconform for manifest validation, and GHCR for SHA-tagged images. Reports are written only by real executions under `reports/`; no sample result is represented as a pass.

The workload is non-root, blocks privilege escalation, drops Linux capabilities, uses a read-only root filesystem with an ephemeral `/tmp`, disables service-account token mounting, applies seccomp, and is isolated by the chart NetworkPolicy. Credentials belong in GitHub repository permissions/secrets or an untracked `.env`, never in source.

Prometheus scrapes `/metrics` every five seconds. Grafana is auto-provisioned with request rate, p95 latency, error rate, process memory, CPU, and application-up panels. Generate traffic with `for i in {1..100}; do curl -s http://localhost:8080/api/status >/dev/null; done`. Confirm target health at Prometheus `/targets` and open the “DevSecOps Application Overview” Grafana dashboard.
