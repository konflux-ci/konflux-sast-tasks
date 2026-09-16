# KFP git URL report

Branch: currently `main` (uncommitted). Move to a dedicated branch before commit.

## Goal

Keep the existing `SITE_DEFAULT` flow. Only add `DEFAULT_KFP_GIT_URL` as an optional override.

Users still pass the string `SITE_DEFAULT` (the Task default). Scripts still check that sentinel, same as before.

## Behavior

When `KFP_GIT_URL` is `SITE_DEFAULT`:

```bash
KFP_GIT_URL="${DEFAULT_KFP_GIT_URL:-https://gitlab.cee.redhat.com/osh/known-false-positives.git}"
```

Then the original probe/clone path runs.

| Situation | Result |
|---|---|
| Param `SITE_DEFAULT`, env empty (current YAML) | Same as today: use the GitLab URL, probe it, clone on internal, skip on OSS |
| Param `SITE_DEFAULT`, env set to another URL | Use that URL instead, then probe/clone |
| Param is an explicit git URL | Unchanged |
| Param is empty | Unchanged; KFP disabled |

Coverity still probes before setting `KFP_GIT_URL`; the URL it probes is `DEFAULT_KFP_GIT_URL` if set, otherwise the GitLab URL.

`DEFAULT_KFP_GIT_URL` is a step env var with `value: ""`. Empty means “use the built-in GitLab URL”, not “skip KFP”.

## Files

Current task versions only: shell-check 0.1, snyk-check 0.5, gitleaks-check 0.1, unicode-check 0.4, coverity-check 0.3 (including oci-ta / min).

## Still needed

1. Feature branch, then commit. Do not mix with PSSECAUT-1604.
2. A real way to set `DEFAULT_KFP_GIT_URL` on a cluster if you want a URL other than GitLab (`value: ""` in the Task will not pick up a pod env). Until then, `SITE_DEFAULT` keeps today’s GitLab behavior.
3. Do not commit `report.md` unless you want it in the PR.
