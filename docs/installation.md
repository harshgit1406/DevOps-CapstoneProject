# Installation and Deployment

## Prerequisites

Windows 11, WSL 2 Ubuntu, Docker Desktop with WSL integration, internet access, and roughly 4 GB free RAM. `setup.sh` checks tools before installing user-local Kind, kubectl, Helm, Terraform, Python packages, Semgrep, and Terraform providers. It does not alter unrelated clusters or containers.

Run `bash setup.sh`, then `bash start.sh`. The latter builds Compose services, creates the dedicated `devops-capstone` Kind cluster if absent, installs Metrics Server, loads the image, upgrades the Helm release, applies Terraform, and waits for rollout health.

Helm upgrade: `helm upgrade devops-capstone helm/devsecops-app -n devops-capstone --set app.version=1.1.0`. Rollback: `helm history devops-capstone -n devops-capstone` then `helm rollback devops-capstone 1 -n devops-capstone`.

Terraform lifecycle: `terraform -chdir=terraform plan`, `apply`, and `destroy`. Terraform manages only `reports/infrastructure.json`; Helm exclusively owns the Kubernetes application resources.

For port conflicts, set `APP_PORT`, `GRAFANA_PORT`, or `PROMETHEUS_PORT` in `.env`. `docker compose ps` shows the resolved host ports.
