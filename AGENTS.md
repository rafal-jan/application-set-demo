# Coding Agent Rules & Project Context

## Project Overview
This project is a local Kubernetes playground using `kind` and `Argo CD`, implementing the **App of Apps** pattern.

## Core Technologies
- **Kubernetes**: `kind` (Kubernetes IN Docker) for clusters.
- **Argo CD**: For GitOps deployment.
- **Helm**: For package management.
- **Envoy Gateway**: For ingress/gateway.

## Directory Structure & Conventions

### Applications (`apps/`)
All applications must reside in the `apps/` directory and follow this structure:

```text
apps/
└── <app-name>/                  # Application name
    ├── chart/                   # Helm chart source
    │   ├── Chart.yaml
    │   └── templates/
    └── values/                  # Environment-specific values
        ├── <cluster-name>/      # e.g., management, workload-1
        │   └── values.yaml
        └── ...
```

### Platform (`.platform/`)
Contains platform-level configurations.
- `apps/`: Platform applications (e.g., gateway).
- `argocd/`: Argo CD ApplicationSet definitions.
- `chart/`: The "Platform" Helm chart (App of Apps).
- `files/`: Configuration files for bootstrapping.
- `global/`: Global configuration values for clusters.
- `bootstrap-management.sh`: Script to bootstrap the management cluster.
- `bootstrap-workload.sh`: Script to bootstrap workload clusters.

**Rule:** Do not modify `.platform/` unless explicitly instructed to change platform-level infrastructure.

## Deployment Workflow
1.  **Add Chart:** Place Helm chart in `apps/<app-name>/chart/`.
2.  **Define Target:** Create `apps/<app-name>/values/<cluster-name>/values.yaml` to enable deployment to a cluster.
3.  **Sync:** Argo CD syncs automatically by default. Disable with `autoSync: false` in `values.yaml`.

## Configuration Hierarchy (Merge Order)
1.  `apps/<app-name>/chart/values.yaml` (Default)
2.  `.platform/global/<cluster-name>.yaml` (Platform Global)
3.  `apps/<app-name>/values/<cluster-name>/values.yaml` (Environment Override)

## General Guidelines
- **Idempotency:** Scripts and commands should be idempotent where possible.
- **Naming:** Follow existing naming conventions (kebab-case for directories/files).
- **Safety:** Always verify current context before applying changes to clusters.
- **Commits:** All commits made by the coding agent must follow [Conventional Commits](https://www.conventionalcommits.org/).
