# Evaluation Rubric Mapping

| Criterion | Evidence |
|---|---|
| Planning & toolchain (20) | Report, architecture and CI diagrams, focused zero-cost tool choices |
| Version control & CI/CD (20) | Git history, PR/push workflow, tests, security gates, GHCR SHA publishing, deployment validation |
| Containers & orchestration (20) | Hardened multi-stage image, Compose, dedicated Kind cluster, Helm, probes, replicas, HPA |
| Automation, monitoring & security (20) | Idempotent scripts, Terraform lifecycle, real Prometheus metrics, provisioned Grafana, Semgrep/Trivy |
| Advanced deployment & docs (40) | Rolling updates, rollback, scaling, self-healing demo, optional quality profile, complete guides |

Acceptance evidence must come from the current machine or CI run. Use `bash status.sh`, `bash demo.sh`, `kubectl get all -n devops-capstone`, generated scan JSON, and GitHub Actions logs.
