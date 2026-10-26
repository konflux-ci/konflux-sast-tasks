#!/bin/bash
set -euo pipefail

TASK_COPY="${1}"
TEST_NS="${2}"

echo "Removing computeResources for task: ${TASK_COPY}"
yq -i eval '.spec.steps[0].computeResources = {}' "${TASK_COPY}"
yq -i eval '.spec.steps[1].computeResources = {}' "${TASK_COPY}"

# SITE_DEFAULT resolves KFP_GIT_URL from konflux-info/cluster-config data.kfp-gitlab-url.
# Seed a tiny public git repo so tests can exercise lookup+clone without the internal GitLab endpoint.
KFP_GIT_URL="https://github.com/octocat/Hello-World.git"

echo "Ensuring konflux-info/cluster-config has kfp-gitlab-url=${KFP_GIT_URL}"
kubectl create namespace konflux-info --dry-run=client -o yaml | kubectl apply -f -

if kubectl get configmap cluster-config -n konflux-info >/dev/null 2>&1; then
  kubectl patch configmap cluster-config -n konflux-info --type merge \
    -p "{\"data\":{\"kfp-gitlab-url\":\"${KFP_GIT_URL}\"}}"
else
  kubectl create configmap cluster-config -n konflux-info \
    --from-literal=kfp-gitlab-url="${KFP_GIT_URL}"
fi

# Task pods use oc get against konflux-info; Kind does not grant that by default.
echo "Granting ${TEST_NS} pipeline SAs get access to konflux-info ConfigMaps"
kubectl create role cluster-config-reader -n konflux-info \
  --verb=get --resource=configmaps \
  --dry-run=client -o yaml | kubectl apply -f - -n konflux-info

kubectl create rolebinding "${TEST_NS}-cluster-config-reader" -n konflux-info \
  --role=cluster-config-reader \
  --serviceaccount="${TEST_NS}:appstudio-pipeline" \
  --serviceaccount="${TEST_NS}:default" \
  --dry-run=client -o yaml | kubectl apply -f - -n konflux-info
