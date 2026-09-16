# KFP git URL report

Branch: `sw/PSSECAUT-1584`

## Goal

Remove the hardcoded internal GitLab KFP endpoint from this open-source repo.
Keep the `SITE_DEFAULT` sentinel. `SITE_DEFAULT` now means “use `DEFAULT_KFP_GIT_URL`”.

## Behavior

When `KFP_GIT_URL` is `SITE_DEFAULT`:

```bash
KFP_GIT_URL="${DEFAULT_KFP_GIT_URL}"
```

Then the original probe/clone path runs. There is no bash `${VAR:-fallback}` and no `gitlab.cee.redhat.com` URL in current non-Coverity tasks.

| Situation | Result |
|---|---|
| Param `SITE_DEFAULT`, env empty (current YAML) | `KFP_GIT_URL` becomes empty; probe/clone is skipped |
| Param `SITE_DEFAULT`, env set to a KFP git URL | Use that URL, then probe/clone |
| Param is an explicit git URL | Unchanged |
| Param is empty | Unchanged; KFP disabled |

`DEFAULT_KFP_GIT_URL` is a step env var with `value: ""`. Empty means skip KFP.

## Files

Current non-Coverity task versions: shell-check 0.1, snyk-check 0.5, gitleaks-check 0.1, unicode-check 0.4 (including oci-ta / min). YAML, param descriptions, env comments, and READMEs no longer mention the GitLab URL.

Coverity tasks are deprecated and were reverted to `origin/main` (still the original hardcoded GitLab probe). Older/archived task versions were left unchanged.

## Still needed

1. Commit the Coverity revert plus this GitLab-fallback removal.
2. A real way to set `DEFAULT_KFP_GIT_URL` on a cluster (`value: ""` in the Task will not pick up a pod env). Until then, `SITE_DEFAULT` skips KFP.
3. Do not commit `report.md` unless you want it in the PR.
