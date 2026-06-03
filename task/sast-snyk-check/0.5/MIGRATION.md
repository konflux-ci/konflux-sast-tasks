# Migration from 0.4 to 0.5

Version 0.5:

- The `--project-name` parameter has been added to all `snyk code test` executions, even if not included in the `ARGS` parameter. This uses the same value as `PROJECT_NAME`.
- If `--project-name` is already included in `ARGS`, there is no change in behavior.
## Change in behaviors
- Scan results may appear in different projects in the Snyk UI since the `--project-name` is now set by default.
-- Default value of `--project-name` is the value of the `PROJECT_NAME` parameter, which if unset, defaults to the name of the Konflux component (`appstudio.openshift.io/component` label).