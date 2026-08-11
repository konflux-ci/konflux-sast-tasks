#!/usr/bin/env bash
# ponytail: local self-check for titled container-layer extract + filter logic.
# Fails if matching model metadata is not extracted, or if weight-like titles would match.
set -euo pipefail

EXTRA_ARTIFACT_FILTER='(^|/)(Dockerfile|Containerfile|[^/]+\.(json|jinja|py|rb|pl|js|mjs|cjs|ts|ps1|sh|bash|zsh|ksh|md|yaml|yml|txt|model))$'

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT
mkdir -p "${workdir}/source" "${workdir}/layer"

# Simulate an olot model layer member at models/config.json
# (olot uses arcname /models/...; extractors typically strip the leading /)
mkdir -p "${workdir}/layer/models"
printf '{"ok":true}\n' >"${workdir}/layer/models/config.json"
tar -cf "${workdir}/layer.tar" -C "${workdir}/layer" models/config.json

title="config.json"
inlayer_path="/models/config.json"
match_path="${inlayer_path#/}"
if ! printf '%s\n' "${match_path}" | grep -Eq "${EXTRA_ARTIFACT_FILTER}" \
  && ! printf '%s\n' "${title}" | grep -Eq "${EXTRA_ARTIFACT_FILTER}"; then
  echo "FAIL: expected config.json to match EXTRA_ARTIFACT_FILTER" >&2
  exit 1
fi

weight_title="model.safetensors"
if printf '%s\n' "${weight_title}" | grep -Eq "${EXTRA_ARTIFACT_FILTER}"; then
  echo "FAIL: safetensors must not match EXTRA_ARTIFACT_FILTER" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
tar -xf "${workdir}/layer.tar" -C "${tmp_dir}"
fetched_count=0
while IFS= read -r -d '' extracted; do
  rel_path="${extracted#"${tmp_dir}"/}"
  rel_path="${rel_path#./}"
  # Task image has GNU realpath -m; keep this check portable for macOS hosts.
  if [[ "${rel_path}" == *".."* ]]; then
    echo "FAIL: path escape: ${rel_path}" >&2
    exit 1
  fi
  dest_path="${workdir}/source/${rel_path}"
  mkdir -p "$(dirname "${dest_path}")"
  cp -a "${extracted}" "${dest_path}"
  fetched_count=$((fetched_count + 1))
done < <(find "${tmp_dir}" -type f -print0)
rm -rf "${tmp_dir}"

if [[ "${fetched_count}" -ne 1 ]]; then
  echo "FAIL: expected 1 extracted file, got ${fetched_count}" >&2
  exit 1
fi
if [[ ! -f "${workdir}/source/models/config.json" ]]; then
  echo "FAIL: missing ${workdir}/source/models/config.json" >&2
  find "${workdir}/source" -print >&2 || true
  exit 1
fi
grep -q '{"ok":true}' "${workdir}/source/models/config.json"

echo "OK: container titled-layer extract self-check passed"
