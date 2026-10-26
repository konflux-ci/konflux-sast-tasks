# KFP `SITE_DEFAULT` test coverage

When `KFP_GIT_URL` is `SITE_DEFAULT`, the latest non-Coverity SAST tasks resolve the URL with:

```bash
KFP_GIT_URL=$(oc get -n konflux-info cm cluster-config -o jsonpath="{.data['kfp-gitlab-url']}" 2>/dev/null || true)
```

An explicit git URL still wins. An empty string still disables KFP. Missing ConfigMap or missing `kfp-gitlab-url` key yields empty and skips KFP.

The cases below cover the new default, plus an explicit GitLab URL overriding cluster-config. That GitLab URL is no longer the default.

Shared fixture for both tests:

- `task/sast-shell-check/0.1/tests/pre-apply-task-hook.sh`
- Creates `konflux-info`, seeds `cluster-config` with `kfp-gitlab-url=https://github.com/octocat/Hello-World.git` (tiny public repo), and RoleBinds the test ServiceAccounts so `oc get`/`oc patch` work.

These tests are modeled on `task/sast-shell-check/0.1/tests/test-sast-shell-check-bad-kfp-repo.yaml`: clone `konflux-ci/test-data-sast`, run `sast-shell-check`, then assert `TEST_OUTPUT` FAILURE with 10 findings (8× SC1083, 2× SC2069) plus a KFP-specific check.

---

## 1. Cluster URL present (`SITE_DEFAULT` lookup succeeds)

**What it covers:** Default param `SITE_DEFAULT` when `konflux-info/cluster-config` has `kfp-gitlab-url`. The task must `oc get` that key and clone it.

**How it was written:** New pipeline copied from the bad-KFP-repo shell-check test. `KFP_GIT_URL` is omitted so the task default applies. `pre-apply-task-hook.sh` seeds Hello-World before any shell-check test runs. An extra check step asserts the clone, not only SARIF counts (a missing key and a failed clone both leave the same 10 findings).

**File:** `task/sast-shell-check/0.1/tests/test-sast-shell-check-kfp-site-default.yaml`  
**Pipeline:** `test-sast-shell-check-kfp-site-default`

**What it does:**

1. Clone `test-data-sast`.
2. Run `sast-shell-check` with no `KFP_GIT_URL` param.
3. Assert `hacbs/sast-shell-check/known-false-positives` origin is `https://github.com/octocat/Hello-World.git`.
4. Assert FAILURE with 10 unfiltered shellcheck findings (`csfilter-kfp` has nothing to apply on Hello-World).

---

## 2. Cluster URL missing (`SITE_DEFAULT` becomes blank)

**What it covers:** Default param `SITE_DEFAULT` when `kfp-gitlab-url` is not on cluster-config. `oc get` returns empty, KFP is skipped.

**How it was written:** Same shell-check pipeline shape as case 1. Named `kfp-unset` so it runs *after* `kfp-site-default` (lexicographic order). A setup task JSON-patches the key off `cluster-config` (hook grants patch for this). Scan still omits `KFP_GIT_URL`. Check asserts there was **no** clone.

**File:** `task/sast-shell-check/0.1/tests/test-sast-shell-check-kfp-unset.yaml`  
**Pipeline:** `test-sast-shell-check-kfp-unset`

**What it does:**

1. Remove `data.kfp-gitlab-url` from `konflux-info/cluster-config` (fail if the key is still set).
2. Clone `test-data-sast`.
3. Run `sast-shell-check` with no `KFP_GIT_URL` param.
4. Assert `known-false-positives/.git` does not exist.
5. Assert FAILURE with the same 10 unfiltered findings.

Related (not this case): `task/sast-shell-check/0.1/tests/test-sast-shell-check-negative.yaml` passes `KFP_GIT_URL: ""` as a param. That is the caller disabling KFP, not `SITE_DEFAULT` reading a missing cluster key.

---

## 3. Explicit GitLab URL (param wins over cluster-config)

**What it covers:** An explicit `KFP_GIT_URL` is used as-is. `SITE_DEFAULT` does not run, so the seeded `cluster-config` URL is ignored.

**How it was written:** Same shell-check pipeline. The scan param is the former hardcoded default, `https://gitlab.cee.redhat.com/osh/known-false-positives.git`. The hook has already set `kfp-gitlab-url` to Hello-World, which is cloneable. Named `kfp-explicit-url` so it runs before `kfp-unset` removes that key.

**File:** `task/sast-shell-check/0.1/tests/test-sast-shell-check-kfp-explicit-url.yaml`  
**Pipeline:** `test-sast-shell-check-kfp-explicit-url`

**What it does:**

1. Clone `test-data-sast`.
2. Run `sast-shell-check` with `KFP_GIT_URL` set to the GitLab known-false-positives URL.
3. If that repo cloned, assert `origin` is the GitLab URL. If it did not (Kind cannot reach GitLab), assert Hello-World was not cloned either.
4. Assert FAILURE with the same 10 unfiltered findings.

---

## How they fit together

| Case | `KFP_GIT_URL` param | Cluster `kfp-gitlab-url` | Expected KFP behavior |
| --- | --- | --- | --- |
| 1. Lookup present | omitted (`SITE_DEFAULT`) | Hello-World.git (hook) | Clone that URL |
| 2. Lookup missing | omitted (`SITE_DEFAULT`) | key removed | Empty URL; skip filter |
| 3. Explicit GitLab URL | known-false-positives.git | Hello-World.git (ignored) | Use the param, not cluster-config |
