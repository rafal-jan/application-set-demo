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

This repository includes a `platform` Helm chart at `.platform/chart` which implements the **App of Apps** pattern. It is designed to be installed on the Management cluster but manages components on the Workload clusters.

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
