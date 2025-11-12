#!/bin/bash

# Validate required environment variables
if [[ -z "${TEST_PREP_RPM_PUSH_DOCKERCONFIG:-}" ]]; then
    echo "ERROR: TEST_PREP_RPM_PUSH_DOCKERCONFIG environment variable is not set"
    exit 1
fi

# should exist as github actions secret, base64 encoded
PUSH_SECRET="${TEST_PREP_RPM_PUSH_DOCKERCONFIG}"
PUSH_SECRET_NAME=prep-rpm-source-push-secret
SERVICE_ACCOUNT_NAME=appstudio-pipeline
echo "Creating image push secret $PUSH_SECRET_NAME in namespace: $2"

# appstudio-pipeline will be created later by run-task-tests.sh script
# but we need it now so we can link it to the push secret
kubectl -n "$2" create serviceaccount "$SERVICE_ACCOUNT_NAME" || true

echo -n "$PUSH_SECRET" | base64 -d > /tmp/dockerconfig.json
kubectl -n "$2" create secret docker-registry "$PUSH_SECRET_NAME" --from-file=/tmp/dockerconfig.json

kubectl -n "$2" patch serviceaccount "$SERVICE_ACCOUNT_NAME" -p '{"imagePullSecrets": [{"name": "'"$PUSH_SECRET_NAME"'"}]}'