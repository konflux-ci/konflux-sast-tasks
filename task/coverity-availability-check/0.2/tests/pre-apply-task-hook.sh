#!/bin/bash

# Create a fake expired Coverity license secret for the expired-license test.
# Uses a different secret name so the existing "no secrets" test is unaffected.
# The expired-license test pipeline passes this name via the COV_LICENSE param.
EXPIRED_LICENSE='<?xml version="1.0" encoding="UTF-8"?>
<coverity>
    <license>
        <version>8</version>
        <product>Static Analysis</product>
        <valid-until>2020-Jan-01 00:00:00 UTC</valid-until>
    </license>
</coverity>'

echo "Creating expired cov-license secret in namespace: $2"
kubectl create secret generic cov-license-expired \
    --from-literal=cov-license="$EXPIRED_LICENSE" \
    --namespace="$2" || true

# Create a fake valid Coverity license secret for the valid-license test.
VALID_LICENSE='<?xml version="1.0" encoding="UTF-8"?>
<coverity>
    <license>
        <version>8</version>
        <product>Static Analysis</product>
        <valid-until>2029-Apr-13 08:00:00 UTC</valid-until>
    </license>
</coverity>'

echo "Creating valid cov-license secret in namespace: $2"
kubectl create secret generic cov-license-valid \
    --from-literal=cov-license="$VALID_LICENSE" \
    --namespace="$2" || true
