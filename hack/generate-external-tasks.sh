#!/bin/bash

# Script to generate external task files with Skopeo digest information
# Iterates over task/<task-name>/<version> directories and creates
# external-task/<task-name>/<version>/<task-name>.yaml files

set -euo pipefail

# Get the script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Base directory containing tasks (relative to repo root)
TASK_DIR="$REPO_ROOT/task"
OUTPUT_DIR="$REPO_ROOT/external-task"
REGISTRY_BASE="quay.io/konflux-ci/tekton-catalog/task"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to process a single task
process_task() {
    local task_path="$1"
    local task_name=$(basename "$(dirname "$task_path")")
    local version=$(basename "$task_path")

    echo "Processing: $task_name/$version"

    # Skip if it's a symlink (archived tasks)
    if [[ -L "$task_path" ]]; then
        echo "  Skipping symlink: $task_path"
        return
    fi

    # Create output directory structure
    local output_task_dir="$OUTPUT_DIR/$task_name/$version"
    mkdir -p "$output_task_dir"

    # Construct container image reference
    local container_ref="docker://$REGISTRY_BASE-$task_name:$version"

    echo "  Inspecting: $container_ref"

    # Get digest using skopeo
    local digest
    if digest=$(skopeo inspect --format '{{.Digest}}' "$container_ref" 2>/dev/null); then
        # Create the full pullspec with digest
        local full_pullspec="$REGISTRY_BASE-$task_name:$version@$digest"

        # Write the YAML file
        local output_file="$output_task_dir/$task_name.yaml"
        echo "task_bundle: $full_pullspec" > "$output_file"

        echo "  ✓ Created: $output_file"
        echo "    task_bundle: $full_pullspec"
    else
        echo "  ✗ Failed to get digest for: $container_ref"
        return 1
    fi
}

# Main execution
echo "Scanning for task directories in $TASK_DIR..."

# Find all task-name/version directories
find "$TASK_DIR" -mindepth 2 -maxdepth 2 -type d | sort | while read -r task_path; do
    process_task "$task_path" || echo "Failed to process: $task_path"
done

echo "Done! External task files created in $OUTPUT_DIR/"