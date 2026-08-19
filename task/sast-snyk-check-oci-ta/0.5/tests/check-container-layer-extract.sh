#!/usr/bin/env bash
# Unit tests for fetch-extra-artifacts.sh (titled container-layer extract + filter).
# Run locally or via tests/test-sast-snyk-check-oci-ta-container-layers.yaml in CI.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${HERE}/fetch-extra-artifacts.sh" ]]; then
  FETCH_SCRIPT="${HERE}/fetch-extra-artifacts.sh"
else
  FETCH_SCRIPT="${HERE}/../fetch-extra-artifacts.sh"
fi

# shellcheck disable=SC1091
source "${FETCH_SCRIPT}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local got="$1" want="$2" msg="$3"
  [[ "${got}" == "${want}" ]] || fail "${msg}: got '${got}' want '${want}'"
}

MODEL_FILTER='(^|/)(Dockerfile|Containerfile|[^/]+\.(json|jinja|py|rb|pl|js|mjs|cjs|ts|ps1|sh|bash|zsh|ksh|md|yaml|yml|txt|model))$'

command -v jq >/dev/null || fail "jq is required"

# --- filter ---
matches_filter "models/config.json" "config.json" "${MODEL_FILTER}" ||
  fail "expected models/config.json to match EXTRA_ARTIFACT_FILTER"
matches_filter "config.json" "config.json" "${MODEL_FILTER}" ||
  fail "expected title config.json to match EXTRA_ARTIFACT_FILTER"
if matches_filter "model.safetensors" "model.safetensors" "${MODEL_FILTER}"; then
  fail "safetensors must not match EXTRA_ARTIFACT_FILTER"
fi
is_container_image_config "application/vnd.oci.image.config.v1+json" ||
  fail "expected oci image config to be detected"
is_image_index "application/vnd.oci.image.index.v1+json" ||
  fail "expected oci image index to be detected"
if is_image_index "application/vnd.oci.image.manifest.v1+json"; then
  fail "image manifest must not be treated as an index"
fi

# --- index resolve ---
index_dir="$(mktemp -d)"
trap 'rm -rf "${index_dir}"' EXIT
cat >"${index_dir}/index.json" <<'EOF'
{
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {"digest": "sha256:arm", "platform": {"architecture": "arm64", "os": "linux"}},
    {"digest": "sha256:amd", "platform": {"architecture": "amd64", "os": "linux"}}
  ]
}
EOF
assert_eq "$(resolve_index_child_digest "${index_dir}/index.json")" "sha256:amd" "linux/amd64 digest"

cat >"${index_dir}/linux-only.json" <<'EOF'
{
  "manifests": [
    {"digest": "sha256:arm", "platform": {"architecture": "arm64", "os": "linux"}}
  ]
}
EOF
assert_eq "$(resolve_index_child_digest "${index_dir}/linux-only.json")" "sha256:arm" "first linux digest fallback"

# --- tar extract (olot-style titled layer) ---
workdir="$(mktemp -d)"
mkdir -p "${workdir}/layer/models" "${workdir}/source"
printf '{"ok":true}\n' >"${workdir}/layer/models/config.json"
tar -cf "${workdir}/layer.tar" -C "${workdir}/layer" models/config.json
extract_dir="$(mktemp -d)"
extract_tarball "${workdir}/layer.tar" "${extract_dir}" "application/vnd.oci.image.layer.v1.tar"
[[ -f "${extract_dir}/models/config.json" ]] || fail "missing extracted models/config.json"
grep -q '{"ok":true}' "${extract_dir}/models/config.json" || fail "extracted file content mismatch"

gz_dir="$(mktemp -d)"
tar -czf "${workdir}/layer.tar.gz" -C "${workdir}/layer" models/config.json
extract_tarball "${workdir}/layer.tar.gz" "${gz_dir}" "application/vnd.oci.image.layer.v1.tar+gzip"
[[ -f "${gz_dir}/models/config.json" ]] || fail "missing gzip-extracted models/config.json"

# --- mocked oras: container image titled layer ---
if ! realpath -m / >/dev/null 2>&1; then
  echo "SKIP: GNU realpath -m not available; mocked oras path not run"
  echo "OK: container titled-layer extract self-check passed"
  exit 0
fi

fake_bin="$(mktemp -d)"
blob_dir="$(mktemp -d)"
digest="sha256:layer1"
cp "${workdir}/layer.tar" "${blob_dir}/${digest}"

cat >"${fake_bin}/oras" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "manifest" && "${2:-}" == "fetch" ]]; then
  cat "${MOCK_MANIFEST}"
  exit 0
fi
if [[ "${1:-}" == "blob" && "${2:-}" == "fetch" ]]; then
  out=""
  ref=""
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then
      out="$2"
      shift 2
      continue
    fi
    if [[ "$1" == *@sha256:* ]]; then
      ref="$1"
    fi
    shift
  done
  digest="${ref##*@}"
  cp "${MOCK_BLOB_DIR}/${digest}" "${out}"
  exit 0
fi
echo "unexpected oras args: $*" >&2
exit 1
EOF
cat >"${fake_bin}/select-oci-auth.sh" <<'EOF'
#!/usr/bin/env bash
echo '{}'
EOF
cat >"${fake_bin}/retry" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
chmod +x "${fake_bin}/oras" "${fake_bin}/select-oci-auth.sh" "${fake_bin}/retry"

MOCK_MANIFEST="${index_dir}/image-manifest.json"
cat >"${MOCK_MANIFEST}" <<EOF
{
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {"mediaType": "application/vnd.oci.image.config.v1+json"},
  "layers": [
    {
      "digest": "${digest}",
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "annotations": {
        "org.opencontainers.image.title": "config.json",
        "olot.layer.content.inlayerpath": "/models/config.json"
      }
    },
    {
      "digest": "sha256:weights",
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "annotations": {
        "org.opencontainers.image.title": "model.safetensors"
      }
    },
    {
      "digest": "sha256:base",
      "mediaType": "application/vnd.oci.image.layer.v1.tar"
    }
  ]
}
EOF

source_root="$(mktemp -d)/source"
mkdir -p "${source_root}"
PATH="${fake_bin}:${PATH}" \
  MOCK_MANIFEST="${MOCK_MANIFEST}" \
  MOCK_BLOB_DIR="${blob_dir}" \
  ORAS_OPTS_FILE="/no-such-oras-opts" \
  SELECT_OCI_AUTH="${fake_bin}/select-oci-auth.sh" \
  SOURCE_ROOT="${source_root}" \
  MANIFEST_FILE="${index_dir}/runtime-manifest.json" \
  FETCH_EXTRA_ARTIFACTS="true" \
  EXTRA_ARTIFACT_FILTER="${MODEL_FILTER}" \
  IMAGE_URL="fake.example/modelcar" \
  IMAGE_DIGEST="sha256:index" \
  bash "${FETCH_SCRIPT}"

[[ -f "${source_root}/models/config.json" ]] || fail "mocked fetch did not extract models/config.json"
if [[ -e "${source_root}/model.safetensors" ]]; then
  fail "weight blob must not be fetched"
fi
grep -q '{"ok":true}' "${source_root}/models/config.json" || fail "extracted artifact content mismatch"

# default-off
FETCH_EXTRA_ARTIFACTS="false" IMAGE_URL="x" IMAGE_DIGEST="y" bash "${FETCH_SCRIPT}" ||
  fail "FETCH_EXTRA_ARTIFACTS=false must exit 0"

echo "OK: container titled-layer extract self-check passed"
