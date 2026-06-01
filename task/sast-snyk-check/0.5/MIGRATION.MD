# Migration from 0.4 to 0.5

Version 0.5:

- The `--project-name` parameter has been added to all `snyk code test` executions, even if not added as ARG
- If `--project-name` is already an ARG, no action is taken
## Change in behaviors
- The scan results from users may appear in new locations since the `--project-name` will now be used even if no ARG provided
-- Default value is the Konflux `COMPONENT_LABEL`