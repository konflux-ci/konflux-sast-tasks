#!/usr/bin/env bash

set -euo pipefail

declare -r pipeline_file=${1:?missing pipeline file}

pmt modify -f "$pipeline_file" task sast-shell-check remove-param CACHI2_ARTIFACT
