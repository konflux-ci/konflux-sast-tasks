#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Removing computeResources for task: $1"
yq -i eval '.spec.steps[].computeResources = {}' $1

if [ -z "${TEST_SNYK_TOKEN}" ]; then
  echo "TEST_SNYK_TOKEN env variable not defined"
  exit 1
fi

# Create snyk secret with value from TEST_SNYK_TOKEN environment variable
SNYK_TOKEN="${TEST_SNYK_TOKEN}"
echo "Creating snyk secret in namespace: $2"
kubectl create secret generic snyk-secret \
    --from-literal=snyk_token="$SNYK_TOKEN" \
    --namespace="$2" || true

echo "Creating fetch-extra-artifacts test ConfigMap in namespace: $2"
kubectl create configmap snyk-fetch-extra-artifacts-test \
    --from-file=check-container-layer-extract.sh="${SCRIPT_DIR}/check-container-layer-extract.sh" \
    --from-file=fetch-extra-artifacts.sh="${SCRIPT_DIR}/../fetch-extra-artifacts.sh" \
    --namespace="$2" \
    --dry-run=client -o yaml | kubectl apply -f -
