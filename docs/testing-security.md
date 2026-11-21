# Testing and Security

Local: `$HOME/.local/share/devops-capstone/venv/bin/pytest -q app/tests`, Semgrep with `.semgrep.yml`, and the Trivy command exposed by `demo.sh`. CI additionally runs secret, dependency, manifest, IaC, Kubernetes, and image checks. The current real outputs are stored in `reports/semgrep.json` and `reports/trivy.json`; regenerate instead of presenting stale reports.
