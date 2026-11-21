# CI/CD Workflow

```mermaid
flowchart LR
  Checkout --> Test --> SAST
  Test --> IaC[IaC validation]
  SAST --> Build
  IaC --> Build
  Build --> Trivy
  Trivy -->|main only| GHCR
  GHCR --> CD[Ephemeral Kind + Helm validation]
```

The workflow grants read-only repository access plus package write permission. GHCR authentication uses the ephemeral `GITHUB_TOKEN`; no local cluster access or static secret is assumed.
