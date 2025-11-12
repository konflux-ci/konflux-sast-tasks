#!/bin/bash

echo "Removing computeResources for task: $1"
yq -i eval '.spec.steps[0].computeResources = {}' $1
yq -i eval '.spec.steps[1].computeResources = {}' $1

if [ -z "${TEST_SNYK_SECRET}" ]; then
  echo "TEST_SNYK_SECRET env variable not defined"
  exit 1
fi

# Create snyk secret with value from TEST_SNYK_SECRET environment variable
SNYK_TOKEN="${TEST_SNYK_SECRET}"
echo "Creating snyk secret in namespace: $2"
kubectl create secret generic snyk-secret \
    --from-literal=snyk_token="$SNYK_TOKEN" \
    --namespace="$2" || true