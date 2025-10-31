#!/bin/bash

echo "Removing computeResources for task: $1"
yq -i eval '.spec.steps[0].computeResources = {}' $1
yq -i eval '.spec.steps[1].computeResources = {}' $1

# Create snyk secret with value from TEST_SNYK_SECRET environment variable
# Default to "fake-token" if not set
SNYK_TOKEN="${TEST_SNYK_SECRET:-fake-token}"
echo "Creating snyk secret in namespace: $2"
kubectl create secret generic snyk-secret \
    --from-literal=snyk_token="$SNYK_TOKEN" \
    --namespace="$2" || true