# sast-gitleaks-check-oci-ta task

gitleaks task

## Parameters
|name|description|default value|required|
|---|---|---|---|
|CACHI2_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the prefetched dependencies.|""|false|
|GITLEAKS_ARGS|Additional CLI arguments to pass to gitleaks|""|false|
|KFP_GIT_URL|Known False Positives (KFP) git URL (optionally taking a revision delimited by \#). Defaults to "SITE_DEFAULT", which means the default value "https://gitlab.cee.redhat.com/osh/known-false-positives.git" for internal Konflux instance and empty string for external Konflux instance. If set to an empty string, the KFP filtering is disabled.|SITE_DEFAULT|false|
|PROJECT_NAME|Name of the scanned project, used to find path exclusions. By default, the Konflux component name will be used.|""|false|
|RECORD_EXCLUDED|Write excluded records in file. Useful for auditing (defaults to false).|false|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|TARGET_DIRS|Target directories in component's source code. Multiple values should be separated with commas.|.|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|image-digest|Digest of the image to scan.||true|
|image-url|Image URL.||true|

## Results
|name|description|
|---|---|
|TEST_OUTPUT|Tekton task test output.|


## Additional info
