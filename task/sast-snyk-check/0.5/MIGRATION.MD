# Migration from 0.4 to 0.5

Version 0.5:

- The `--project-name` parameter has been added to all `snyk code test` executions, even if not included in the `ARGS` parameter. This uses the same value as `PROJECT_NAME`.
- If `--project-name` is already included in `ARGS`, there is no change in behavior.
## Change in behaviors
- The scan results from users may appear in new locations since the `--project-name` will now be used even if no ARG provided
-- Default value is the Konflux `COMPONENT_LABEL`