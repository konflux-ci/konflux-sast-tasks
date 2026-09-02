#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o posix

shopt -s globstar nullglob

command -v go &> /dev/null || { echo Please install golang to run this tool; exit 1; }
[[ "$(go env GOVERSION)" == @(go1|go1.[1-9]+(|.*|rc*|beta*)|go1.1[0-9]+(|.*|rc*|beta*)|go1.20*) ]] && { echo Please install golang 1.21.0 or newer; exit 1; }

HACK_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
ROOT_DIR="$(git rev-parse --show-toplevel)"
TASK_DIR="$(realpath "${ROOT_DIR}/task")"

tashbin="$(mktemp --dry-run)"
GOTOOLCHAIN=auto GOSUMDB=sum.golang.org go build -C "${ROOT_DIR}/task-generator/trusted-artifacts" -o "${tashbin}"
trap 'rm "${tashbin}"' EXIT
tash() {
  "${tashbin}" "$@"
}

# Keep additionalSteps[].script in recipe.yaml identical to a sibling
# fetch-extra-artifacts.sh when that file exists (unit-tested helper).
sync_fetch_extra_artifacts_script() {
  local recipe_path="$1"
  local script_path="$2"
  python3 - "${recipe_path}" "${script_path}" <<'PY'
from pathlib import Path
import sys

recipe_path, script_path = Path(sys.argv[1]), Path(sys.argv[2])
script = script_path.read_text()
if not script.endswith("\n"):
    script += "\n"
indented = "".join(
    "\n" if line == "\n" else f"      {line}"
    for line in script.splitlines(keepends=True)
)
text = recipe_path.read_text()
marker = "    name: fetch-extra-artifacts\n"
start = text.find(marker)
if start < 0:
    sys.exit(f"ERROR: {recipe_path}: fetch-extra-artifacts step not found")
key = "    script: |\n"
sidx = text.find(key, start)
if sidx < 0:
    sys.exit(f"ERROR: {recipe_path}: script: | not found under fetch-extra-artifacts")
body = sidx + len(key)
end = text.find("\n    computeResources:", body)
if end < 0:
    sys.exit(f"ERROR: {recipe_path}: computeResources after script not found")
updated = text[:body] + indented + text[end + 1 :]
if updated != text:
    recipe_path.write_text(updated)
PY
}

declare -i changes=0
emit() {
  if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
    printf "::error file=%s,line=1,col=0::%s\n" "$1" "$2"
  else
    printf "INFO: \033[1m%s\033[0m %s\n" "$1" "$2"
  fi
  changes=$((changes + 1))
}

msg="File is out of date and has been updated"
if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
  # shellcheck disable=SC2016
  msg='File is out of date, run `hack/generate-ta-tasks.sh` and include the updated file with your changes.'
  msg+=' Or run ./hack/generate-everything.sh to run all the generators at once.'
fi

cd "${TASK_DIR}"
for recipe_path in **/recipe.yaml; do
    task_path="${recipe_path%/recipe.yaml}/$(basename "${recipe_path%/*/*}").yaml"
    script_src="${recipe_path%/recipe.yaml}/fetch-extra-artifacts.sh"
    if [[ -f "${script_src}" ]]; then
        sync_fetch_extra_artifacts_script "${TASK_DIR}/${recipe_path}" "${TASK_DIR}/${script_src}"
    fi
    sponge=$(tash "${TASK_DIR}/${recipe_path}")
    echo "${sponge}" > "${task_path}"
    readme_path="${recipe_path%/recipe.yaml}/README.md"
    "${HACK_DIR}/generate-readme.sh" "${task_path}" "${readme_path}"
    if ! git diff --quiet HEAD "${task_path}"; then
        emit "task/${task_path}" "${msg}"
    fi
    if ! git diff --quiet HEAD "${readme_path}"; then
        emit "task/${readme_path}" "${msg}"
    fi
    if [[ -f "${script_src}" ]] && ! git diff --quiet HEAD "${recipe_path}"; then
        emit "task/${recipe_path}" "${msg}"
    fi
done

if [[ ${changes} -gt 0 ]]; then
  if [ "${GITHUB_ACTIONS:-false}" == "true" ]; then
    # shellcheck disable=SC2016
    echo '::notice title=Apply the attached patch::Download the attached `ta.patch` file and run `git apply ta.patch`'
    git diff -u | tee "${ROOT_DIR}/ta.patch"
    exit 1
  else
    printf "INFO: \033[1mMake sure to include the regenerated files in your changeset\033[0m\n"
  fi
fi
