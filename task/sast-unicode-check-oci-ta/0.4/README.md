# sast-unicode-check-oci-ta task

Scans source code for non-printable unicode characters in all text files.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|EXTRA_ARTIFACT_FILTER|Extended regex matching org.opencontainers.image.title and olot.layer.content.inlayerpath when present and FETCH_EXTRA_ARTIFACTS=true.|(^&#124;/)(Dockerfile&#124;Containerfile&#124;[^/]+[.](json&#124;yaml&#124;yml&#124;toml&#124;jinja&#124;jinja2&#124;sh&#124;bash&#124;zsh&#124;ksh&#124;py))$|false|
|FETCH_EXTRA_ARTIFACTS|When "true", fetch files matching EXTRA_ARTIFACT_FILTER from image-url@image-digest into /var/workdir/source alongside the restored SOURCE_ARTIFACT. Supports raw OCI artifacts and titled layers in container images such as ModelCar.|false|false|
|FIND_UNICODE_CONTROL_ARGS|arguments for find-unicode-control command.|-p bidi -v -d -t|false|
|KFP_GIT_URL|Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|RECORD_EXCLUDED|Whether to record the excluded findings (defaults to false). If `true`, the excluded findings will be stored in `excluded-findings.json`. |false|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|TARGET_DIRS|Target directories in component's source code. Multiple values should be separated with commas.|.|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-digest|Image digest used for ORAS upload.||true|
|image-url|Image URL used for ORAS upload.||true|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|


## Additional info

Set `FETCH_EXTRA_ARTIFACTS` to `"true"` to fetch the default set of metadata
and scripts from a raw OCI artifact or matching titled ModelCar image layers before scanning. Override
`EXTRA_ARTIFACT_FILTER` to narrow or extend that set. For example, use
`[.]json$` to fetch only JSON files. The scanner still applies its MIME checks
to fetched files.
