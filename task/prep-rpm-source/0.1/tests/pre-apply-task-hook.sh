#!/bin/bash

# these should exist as github actions secrets
PUSH_PASSWORD="${TEST_PREP_RPM_PUSH_PASSWORD}"
PUSH_USERNAME="${TEST_PREP_RPM_PUSH_USERNAME}"
PUSH_SECRET_NAME=prep-rpm-source-push-secret
SERVICE_ACCOUNT_NAME=appstudio-pipeline
echo "Creating image push secret in namespace: $2"

kubectl --namespace "$2" create secret docker-registry "$PUSH_SECRET_NAME" \
  --docker-username "$PUSH_USERNAME" --docker-password "$PUSH_PASSWORD"
kubectl --namespace "$2" patch serviceaccount "$SERVICE_ACCOUNT_NAME" -p '{"imagePullSecrets": [{"name": "'"$MY_SECRET_NAME"'"}]}'