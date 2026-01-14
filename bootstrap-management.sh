#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="management"
KIND_CONFIG="files/management-cluster.yaml"
HOST_PORT=8080

echo "----------------------------------------------------"
echo "Bootstrapping Management Cluster"
echo "----------------------------------------------------"

# 1. Create Cluster (Idempotent)
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
    echo "Creating cluster '$CLUSTER_NAME'..."
    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
fi

# 2. Install Argo CD
echo "Installing Argo CD with Helm..."
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update argocd
helm upgrade --install argocd argocd/argo-cd \
  --namespace argocd \
  --create-namespace \
  --kube-context "kind-$CLUSTER_NAME" \
  -f files/argocd-values.yaml \
  --wait

# 3. Wait for Readiness
echo "Waiting for Argo CD to be accessible at http://localhost:$HOST_PORT..."
for i in {1..60}; do
  if curl -k -s -o /dev/null http://localhost:$HOST_PORT; then
    echo "Argo CD is accessible!"
    break
  fi
  sleep 5
done

# 4. Configure Repository Access
echo "Configuring Argo CD repository access..."

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI not found. Please install GitHub CLI."
    exit 1
fi

# Check gh auth status
if ! gh auth status &> /dev/null; then
    echo "Error: gh CLI not authenticated. Please run 'gh auth login'."
    exit 1
fi

export REPO_URL=$(gh repo view --json url -q .url)
export GITHUB_TOKEN=$(gh auth token)

echo "Adding repository $REPO_URL to Argo CD..."

envsubst < files/repo-access.yaml | kubectl apply -f -

# 5. Install Platform Components
echo "Installing Platform Components..."
envsubst < files/platform-application.yaml | kubectl apply -f -

# 6. Output Credentials
echo "Retrieving initial admin password..."
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context "kind-$CLUSTER_NAME" | base64 -d)

echo "----------------------------------------------------"
echo "Management Bootstrap Complete!"
echo "Argo CD URL: http://localhost:8080"
echo "Username: admin"
echo "Password: $PASSWORD"
echo "----------------------------------------------------"
