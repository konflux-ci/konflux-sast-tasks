#!/bin/bash

echo "Removing computeResources for task: $1"
yq -i eval '.spec.steps[].computeResources = {}' $1

# The Kind registry TLS certificate is not reliably trusted through the
# mounted trusted-ca bundle with deploy-local CI. This modifies only the
# temporary task copy used by the integration test.
yq -i '
  .spec.stepTemplate.env = (.spec.stepTemplate.env // []) + [
    {"name": "ORAS_OPTIONS", "value": "--insecure"}
  ]
' "$1"

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
