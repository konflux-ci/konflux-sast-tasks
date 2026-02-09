#!/bin/bash

echo "Removing computeResources for task: $1"
yq -i eval '.spec.steps[0].computeResources = {}' $1
yq -i eval '.spec.steps[1].computeResources = {}' $1

if [ -n "${TEST_SNYK_TOKEN}" ]; then
  # Create snyk secret with value from TEST_SNYK_TOKEN environment variable
  echo "Creating snyk secret in namespace: $2"
  kubectl create secret generic snyk-secret \
      --from-literal=snyk_token="${TEST_SNYK_TOKEN}" \
      --namespace="$2" || true
else
  echo "TEST_SNYK_TOKEN not set; task will run in skip mode (no secret created)"
fi