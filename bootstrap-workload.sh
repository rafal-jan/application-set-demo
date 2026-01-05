#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <cluster-name>"
  exit 1
fi

export CLUSTER_NAME="$1"
MGMT_CLUSTER="management"

echo "----------------------------------------------------"
echo "Bootstrapping Workload Cluster: $CLUSTER_NAME"
echo "----------------------------------------------------"

# 1. Create Cluster
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
export HOST_PORT="${2:-8081}"

    echo "Creating cluster '$CLUSTER_NAME' with host port mapping $HOST_PORT:30080..."
    # Add control plane container name to certSANs for internal communication
    envsubst < files/workload-cluster.yaml | kind create cluster --name "$CLUSTER_NAME" --config -
fi

# 2. Register in Management Cluster
echo ">> Registering '$CLUSTER_NAME' in Argo CD (Management Cluster)..."

# Helper function to get kubeconfig user data
get_user_data() {
  local c_name=$1
  local jsonpath=$2
  kubectl config view -o jsonpath="{.users[?(@.name==\"kind-${c_name}\")].user.${jsonpath}}" --raw
}

# Check if already registered (optional, we apply idempotently)
# if kubectl get secret "${CLUSTER_NAME}-cluster-secret" ... 
# We remove the check to ensure config (like CA data) is updated if script is re-run.

echo ">> Updating registration for '$CLUSTER_NAME' in Argo CD..."

# Extract credentials
export CERT_DATA=$(get_user_data "$CLUSTER_NAME" "client-certificate-data")
export KEY_DATA=$(get_user_data "$CLUSTER_NAME" "client-key-data")
# Extract CA Data (cluster-level)
export CA_DATA=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"kind-${CLUSTER_NAME}\")].cluster.certificate-authority-data}" --raw)

# Internal URL
SERVER_URL="https://${CLUSTER_NAME}-control-plane:6443"

# Config JSON
CONFIG_JSON=$(envsubst < files/argo-cluster-config.json)

# Create Secret
kubectl create secret generic "${CLUSTER_NAME}-cluster-secret" \
  -n argocd \
  --context "kind-$MGMT_CLUSTER" \
  --from-literal=name="$CLUSTER_NAME" \
  --from-literal=server="$SERVER_URL" \
  --from-literal=config="$CONFIG_JSON" \
  --dry-run=client -o yaml | \
  kubectl label -f - --local=true -o yaml "argocd.argoproj.io/secret-type=cluster" | \
  kubectl apply --context "kind-$MGMT_CLUSTER" -f -
  
echo "Registered '$CLUSTER_NAME' successfully."

echo "----------------------------------------------------"
echo "Workload '$CLUSTER_NAME' Ready!"
echo "----------------------------------------------------"

# 3. Install Platform Components
echo ">> Installing Platform Components for '$CLUSTER_NAME'..."

envsubst < files/platform-application.yaml | kubectl apply --context "kind-$MGMT_CLUSTER" -f -

echo "Platform components installation initiated."

