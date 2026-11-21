# Troubleshooting

- Docker unavailable: start Docker Desktop and enable Settings > Resources > WSL Integration for Ubuntu.
- Port busy: change the corresponding value in `.env`, then rerun `bash start.sh`.
- Pod `ImagePullBackOff`: run `kind load docker-image devops-capstone:local --name devops-capstone`, then restart the deployment.
- HPA shows unknown: wait for Metrics Server, then inspect `kubectl logs -n kube-system deployment/metrics-server`.
- Helm timeout: run `kubectl describe pod -n devops-capstone` and `kubectl get events -n devops-capstone --sort-by=.lastTimestamp`.
- Grafana has no data: verify `http://localhost:9090/targets`, call the application repeatedly, and confirm the Compose app is healthy.
- Reset only this project: `bash cleanup.sh`; it asks before removing the named cluster, Compose volumes, or Terraform state.
