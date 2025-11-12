#!/bin/bash

# Validate required environment variables
if [[ -z "${TEST_PREP_RPM_PUSH_DOCKERCONFIG:-}" ]]; then
    echo "ERROR: TEST_PREP_RPM_PUSH_DOCKERCONFIG environment variable is not set"
    exit 1
fi

# these should exist as github actions secrets
# PUSH_PASSWORD="${TEST_PREP_RPM_PUSH_PASSWORD}"
# PUSH_USERNAME="${TEST_PREP_RPM_PUSH_USERNAME}"
PUSH_SECRET="${TEST_PREP_RPM_PUSH_DOCKERCONFIG}" # should be base64 encoded
PUSH_SECRET_NAME=prep-rpm-source-push-secret
SERVICE_ACCOUNT_NAME=appstudio-pipeline
echo "Creating image push secret $PUSH_SECRET_NAME in namespace: $2"

kubectl get sa

kubectl -n "$2" create serviceaccount "$SERVICE_ACCOUNT_NAME" || true

echo -n "$PUSH_SECRET" | base64 -d > /tmp/dockerconfig.json
kubectl -n "$2" create secret docker-registry "$PUSH_SECRET_NAME" --from-file=/tmp/dockerconfig.json
# kubectl -n "$2" create secret docker-registry "$PUSH_SECRET_NAME" --docker-username "$PUSH_USERNAME" --docker-password "$PUSH_PASSWORD"

kubectl -n "$2" patch serviceaccount "$SERVICE_ACCOUNT_NAME" -p '{"imagePullSecrets": [{"name": "'"$PUSH_SECRET_NAME"'"}]}'