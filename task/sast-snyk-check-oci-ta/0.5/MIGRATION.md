# Migration from 0.4 to 0.5

Version 0.5:

- The `--project-name` parameter has been added to all `snyk code test` executions, even if not included in the `ARGS` parameter. This uses the same value as `PROJECT_NAME`.
- If `--project-name` is already included in `ARGS`, there is no change in behavior.
- New optional parameters `FETCH_EXTRA_ARTIFACTS` and `EXTRA_ARTIFACT_FILTER` for scanning OCI-packaged script artifacts. Not enabled by default.

## Change in behaviors

- Scan results may appear in different projects in the Snyk UI since the `--project-name` is now set by default.
- Default value of `--project-name` is the value of the `PROJECT_NAME` parameter, which if unset, defaults to the name of the Konflux component (`appstudio.openshift.io/component` label).

## FETCH_EXTRA_ARTIFACTS and container images (ModelCar)

When `FETCH_EXTRA_ARTIFACTS=true`:

- **OCI artifacts** (unchanged): fetch raw blobs whose `org.opencontainers.image.title` matches `EXTRA_ARTIFACT_FILTER`.
- **Container images** (new): no longer skipped. For layers with a title annotation (e.g. ModelCar/olot layers), matching layers are blob-fetched and untarred into `/var/workdir/source`. Base-image layers without titles and non-matching weight blobs are not pulled.
- **Image indexes**: multi-arch indexes are resolved to a single linux/amd64 (else first linux) manifest before layer extraction.

To scan ModelCar model metadata files (not weights), set e.g.:

```yaml
- name: FETCH_EXTRA_ARTIFACTS
  value: "true"
- name: EXTRA_ARTIFACT_FILTER
  value: '(^|/)(Dockerfile|Containerfile|[^/]+\.(json|jinja|py|rb|pl|js|mjs|cjs|ts|ps1|sh|bash|zsh|ksh|md|yaml|yml|txt|model))$'
- name: TARGET_DIRS
  value: models
```
