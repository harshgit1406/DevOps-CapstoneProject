# Viva Questions and Answers

1. **Why Kind?** Real, reproducible Kubernetes nodes run locally in Docker at zero cost.
2. **How does self-healing work?** The Deployment controller restores the declared replica count.
3. **Readiness versus liveness?** Readiness gates traffic; liveness triggers process replacement.
4. **Why Helm?** It provides parameterized releases, upgrades, history, and rollback.
5. **Why Terraform too?** It demonstrates a separate declarative infrastructure lifecycle without competing with Helm.
6. **What blocks release?** Tests and required security jobs must succeed before GHCR publishing.
7. **How are metrics real?** Request hooks and the Python process exporter update Prometheus series from live traffic.
8. **What is immutable deployment?** CI identifies images using a commit SHA/digest rather than an ambiguous moving tag.
