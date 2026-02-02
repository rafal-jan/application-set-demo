# Developer Guide: Deploying Applications

**Note:** To set up the local Kubernetes environment (management and workload
clusters), please refer to the [Platform Guide](.platform/README.md).

This platform uses Argo CD ApplicationSets to automatically manage deployments
across clusters. The system follows a convention-based directory structure to
determine **what** to deploy and **where** to deploy it.

## Directory Structure

To deploy an application, you must follow this specific directory structure
inside the `apps/` folder:

```text
apps/
└── <app-name>/                  # 1. Your application name (e.g., my-service)
    ├── chart/                   # 2. Your Helm chart goes here
    │   ├── Chart.yaml
    │   └── templates/
    └── values/                  # 3. Environment-specific configurations
        ├── <cluster-name>/      # 4. Target cluster name (e.g., workload-1)
        │   └── values.yaml      # 5. Overrides for this specific cluster
        └── <another-cluster>/
            └── values.yaml
```

## Step-by-Step Deployment

### 1. Add Your Helm Chart

Create a directory for your application in `apps/` and place your Helm chart
inside a `chart` subdirectory.

Example: `apps/my-service/chart/`

### 2. Define Target Environments

To deploy your application to a specific cluster (e.g., `workload-1`), create a
`values.yaml` file inside `apps/<app-name>/values/workload-1/`.

- **Path:** `apps/my-service/values/workload-1/values.yaml`
- **Content:** This file contains Helm values specific to that environment.
  Even an empty file `{}` is sufficient to trigger the deployment.

### 3. Configuration Hierarchy

The application will be deployed using Helm with values merged in this order
(latter overrides former):

1. **Default Values:** `apps/<app-name>/chart/values.yaml` (from your chart)
2. **Global Platform Config:** `.platform/global/<cluster-name>.yaml` (managed
   by platform team)
3. **App Environment Config:**
   `apps/<app-name>/values/<cluster-name>/values.yaml` (your specific
   overrides)

### 4. Automatic Sync Control

By default, applications sync automatically. You can disable this per
environment by adding the following to your environment's `values.yaml`:

```yaml
autoSync: false
```
