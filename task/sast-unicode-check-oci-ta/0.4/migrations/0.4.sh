#!/usr/bin/env bash

set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

tasks_root=".spec.tasks[]"
if yq -e ".spec.pipelineSpec.tasks" "$pipeline_file" &>/dev/null; then
  tasks_root=".spec.pipelineSpec.tasks[]"
fi

# Remove FIND_UNICODE_CONTROL_URL parameter from sast-unicode-check task if it exists.
if yq -e "$tasks_root"' | select(.name == "sast-unicode-check").params[] | select(.name == "FIND_UNICODE_CONTROL_URL")' "$pipeline_file" >/dev/null; then
    echo "Removing FIND_UNICODE_CONTROL_URL parameter from sast-unicode-check task"
    yq -i "($tasks_root | select(.name == \"sast-unicode-check\").params) |= map(select(.name != \"FIND_UNICODE_CONTROL_URL\"))" "$pipeline_file"
else
    echo "FIND_UNICODE_CONTROL_URL parameter not found in sast-unicode-check task. Nothing to remove."
fi

# Remove FIND_UNICODE_CONTROL_URL parameter from sast-unicode-check-oci-ta task if it exists.
if yq -e "$tasks_root"' | select(.name == "sast-unicode-check-oci-ta").params[] | select(.name == "FIND_UNICODE_CONTROL_URL")' "$pipeline_file" >/dev/null; then
    echo "Removing FIND_UNICODE_CONTROL_URL parameter from sast-unicode-check-oci-ta task"
    yq -i "($tasks_root | select(.name == \"sast-unicode-check-oci-ta\").params) |= map(select(.name != \"FIND_UNICODE_CONTROL_URL\"))" "$pipeline_file"
else
    echo "FIND_UNICODE_CONTROL_URL parameter not found in sast-unicode-check-oci-ta task. Nothing to remove."
fi
