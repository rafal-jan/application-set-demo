#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="management"
KIND_CONFIG="clusters/management.yaml"
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
# Check if Argo CD is already installed by looking for the release
if helm status argocd -n argocd --kube-context "kind-$CLUSTER_NAME" &> /dev/null; then
  echo "Argo CD release exists. Skipping installation."
else
  kubectl create namespace argocd --context "kind-$CLUSTER_NAME" --dry-run=client -o yaml | kubectl apply --context "kind-$CLUSTER_NAME" -f -
  
  helm repo add argocd https://argoproj.github.io/argo-helm
  helm repo update argocd
  helm upgrade --install argocd argocd/argo-cd \
    --namespace argocd \
    --kube-context "kind-$CLUSTER_NAME" \
    -f argocd-values.yaml \
    --wait
fi

# 3. Wait for Readiness
echo "Waiting for Argo CD to be accessible at http://localhost:$HOST_PORT..."
for i in {1..60}; do
  if curl -k -s -o /dev/null http://localhost:$HOST_PORT; then
    echo "Argo CD is accessible!"
    break
  fi
  sleep 5
done

# 4. Output Credentials
echo "Retrieving initial admin password..."
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context "kind-$CLUSTER_NAME" | base64 -d)

echo "----------------------------------------------------"
echo "Management Bootstrap Complete!"
echo "Argo CD URL: http://localhost:8080"
echo "Username: admin"
echo "Password: $PASSWORD"
echo "----------------------------------------------------"
