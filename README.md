# Application Set Demo

Local Kubernetes playground using `kind` and Argo CD.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

## Getting Started

### 1. Management Cluster

To spin up the management cluster and install Argo CD, run:

```bash
./bootstrap-management.sh
```

This script will:

1. Create a `kind` cluster named `management`.
2. Install Argo CD.
3. Expose Argo CD on localhost:8080.
4. Print the initial admin password.

### 2. Workload Clusters

To create and register a workload cluster (e.g., `workload-1`), run:

```bash
./bootstrap-workload.sh <cluster_name> [host_port]
```

Example:

```bash
./bootstrap-workload.sh workload-1 8081
```

This script will:

1. Create a `kind` cluster named `<cluster_name>`.
2. Map container port `30080` to the specified host port (default `8081`) for Gateway access.
3. Register the cluster in the management cluster's Argo CD using local credentials.

### 3. Platform Components

This repository includes a `platform` Helm chart which implements the **App of Apps** pattern. It is designed to be installed on the Management cluster but manages components on the Workload clusters.

Default components:

- **Envoy Gateway**: Installed in `envoy-gateway-system` namespace. Exposed via NodePort `30080`.

## Accessing Argo CD

- **URL**: [http://localhost:8080](http://localhost:8080)
- **Username**: `admin`
- **Password**: (Printed at the end of `bootstrap.sh`)

If you need to retrieve the password again:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## Teardown

To destroy the cluster:

```bash
kind delete cluster --name management
```

## Developer Guide: Deploying Applications

This platform uses Argo CD ApplicationSets to automatically manage deployments across clusters. The system follows a convention-based directory structure to determine **what** to deploy and **where** to deploy it.

### Directory Structure

To deploy an application, you must follow this specific directory structure inside the `apps/` folder:

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

### Step-by-Step Deployment

#### 1. Add Your Helm Chart
Create a directory for your application in `apps/` and place your Helm chart inside a `chart` subdirectory.

Example: `apps/my-service/chart/`

#### 2. Define Target Environments
To deploy your application to a specific cluster (e.g., `workload-1`), create a `values.yaml` file inside `apps/<app-name>/values/workload-1/`.

*   **Path:** `apps/my-service/values/workload-1/values.yaml`
*   **Content:** This file contains Helm values specific to that environment. Even an empty file `{}` is sufficient to trigger the deployment.

#### 3. Configuration Hierarchy
The application will be deployed using Helm with values merged in this order (latter overrides former):

1.  **Default Values:** `apps/<app-name>/chart/values.yaml` (from your chart)
2.  **Global Platform Config:** `.platform/global/<cluster-name>.yaml` (managed by platform team)
3.  **App Environment Config:** `apps/<app-name>/values/<cluster-name>/values.yaml` (your specific overrides)

#### 4. Automatic Sync Control
By default, applications sync automatically. You can disable this per environment by adding the following to your environment's `values.yaml`:

```yaml
autoSync: false
```