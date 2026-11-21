# Five-minute Faculty Demonstration

1. Run `bash status.sh`; show the dashboard, `/api/status`, Grafana, and Prometheus targets.
2. Select tests in `bash demo.sh`; explain that endpoint and metrics behavior is automatically verified.
3. Select scale; watch two pods become five and return to two.
4. Select self-heal; delete one pod and watch Kubernetes replace it.
5. Select rollout/rollback; watch a rolling revision complete and then undo.
6. Select Terraform; show the plan/apply inventory output.
7. Select security; show only the actual Semgrep/Trivy execution and generated reports.
8. Close with the GitHub Actions pipeline and rubric mapping.

## Viva quick answers

- **Why Kind?** It is lightweight, free, reproducible, and uses real Kubernetes nodes in Docker.
- **Why Helm and Terraform?** Helm manages release lifecycle inside Kubernetes; Terraform manages separate local infrastructure evidence, avoiding ownership conflicts.
- **How does self-healing work?** The Deployment controller continuously reconciles actual pods to the desired replica count.
- **Liveness vs readiness?** Liveness restarts an unhealthy process; readiness removes a temporarily unavailable pod from service endpoints.
- **Why immutable SHA images?** A commit-specific tag/digest makes releases traceable and prevents silent tag drift.
- **What stops an unsafe release?** Required test and scanning jobs must pass before the publish job runs.
- **How is latency measured?** A Flask request hook records durations in a Prometheus histogram; Grafana calculates p95.
- **Why no database?** The dashboard is stateless, so a database adds cost and failure modes without supporting the objective.
