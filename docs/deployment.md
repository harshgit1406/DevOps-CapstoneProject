# Deployment Guide

Run `bash start.sh` for an idempotent Compose + Kind + Helm + Terraform deployment. Inspect with `bash status.sh`. Upgrade with `helm upgrade devops-capstone helm/devsecops-app -n devops-capstone --reuse-values`; view revisions with `helm history`; roll back with `helm rollback devops-capstone REVISION -n devops-capstone`. Stop services non-destructively with `bash stop.sh`; use `bash cleanup.sh` only when project-specific resource deletion is intended.
