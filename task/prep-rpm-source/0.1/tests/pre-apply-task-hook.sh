#!/bin/bash

# these should exist as github actions secrets
# PUSH_PASSWORD="${TEST_PREP_RPM_PUSH_PASSWORD}"
# PUSH_USERNAME="${TEST_PREP_RPM_PUSH_USERNAME}"
PUSH_SECRET="${TEST_PREP_RPM_PUSH_DOCKERCONFIG}" # should be base64 encoded
PUSH_SECRET_NAME=prep-rpm-source-push-secret
SERVICE_ACCOUNT_NAME=default
echo "Creating image push secret $PUSH_SECRET_NAME in namespace: $2"

kubectl get sa

echo $PUSH_SECRET | base64 -d > /tmp/dockerconfig.json
kubectl -n "$2" create secret docker-registry "$PUSH_SECRET_NAME" --from-file=/tmp/dockerconfig.json
# kubectl -n "$2" create secret docker-registry "$PUSH_SECRET_NAME" --docker-username "$PUSH_USERNAME" --docker-password "$PUSH_PASSWORD"

kubectl -n "$2" patch serviceaccount "$SERVICE_ACCOUNT_NAME" -p '{"imagePullSecrets": [{"name": "'"$PUSH_SECRET_NAME"'"}]}'