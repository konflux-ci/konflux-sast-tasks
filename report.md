# KFP git URL report

Branch: currently `main` (uncommitted working-tree changes). These edits should move to a dedicated branch before commit.

## Problem

`KFP_GIT_URL` defaults to `SITE_DEFAULT`. Until now, that sentinel was rewritten in the task script to a hardcoded internal GitLab URL:

```bash
KFP_GIT_URL="https://gitlab.cee.redhat.com/osh/known-false-positives.git"
```

Open-source / external Konflux then probes an internal hostname, fails, and skips KFP filtering. The URL also cannot be changed per cluster without forking the task.

## What was done

Re-applied the previous (stashed) KFP URL work on current `main`.

When `KFP_GIT_URL` is `SITE_DEFAULT`, tasks now copy `DEFAULT_KFP_GIT_URL` instead of the hardcoded GitLab URL. `DEFAULT_KFP_GIT_URL` is a step env var, empty by default. Internal clusters are expected to set it to their KFP repo; if it is empty, KFP filtering is skipped.

### Behavior

| `KFP_GIT_URL` param | Result |
|---|---|
| `SITE_DEFAULT` and `DEFAULT_KFP_GIT_URL` is set | Use that URL (Coverity still probes it first) |
| `SITE_DEFAULT` and `DEFAULT_KFP_GIT_URL` is empty | Treat as unset; skip KFP |
| explicit git URL | Unchanged; clone/filter as before |
| empty string | Unchanged; KFP disabled |

### Files touched (current task versions only)

- shell-check 0.1 (base, oci-ta, oci-ta-min)
- snyk-check 0.5 (base, oci-ta)
- gitleaks-check 0.1 (base, oci-ta)
- unicode-check 0.4 (base, oci-ta, oci-ta-min)
- coverity-check 0.3 (`patch.yaml`, generated yaml, oci-ta)

Each of those: param description, `DEFAULT_KFP_GIT_URL` env (`value: ""`), `SITE_DEFAULT` handling, and README `KFP_GIT_URL` row.

Coverity is slightly different from the clone-based tasks: it already probed the URL before using it. That probe now uses `DEFAULT_KFP_GIT_URL` instead of `gitlab.cee.redhat.com`.

Archived tasks, tests, and older versions (unicode 0.2/0.3, snyk 0.4) were left alone.

## What is still needed

1. **Move off `main`** onto a feature branch, then commit. Do not mix this with PSSECAUT-1604.

2. **Wire `DEFAULT_KFP_GIT_URL` on internal clusters.** The Task sets `value: ""`, so a cluster-wide pod env will **not** override it. Internal Konflux needs a real injection path (controller overlay, kustomize patch, or a Task param). Until that exists, `SITE_DEFAULT` skips KFP everywhere, including internal.

3. **Confirm tests.** Pipelines that pass an explicit `KFP_GIT_URL` are fine. Anything that relied on `SITE_DEFAULT` actually cloning `gitlab.cee.redhat.com` will now skip filtering unless `DEFAULT_KFP_GIT_URL` is populated.

4. **Optional:** older still-shipped versions (`sast-snyk-check/0.4`, `sast-unicode-check/0.2` and `0.3`) still hardcode the GitLab URL.

5. **Do not commit `report.md`** with the task change unless you want it in the PR.
