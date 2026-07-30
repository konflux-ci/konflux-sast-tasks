# Migration from 0.5 to 0.6

Version 0.6:

- The unused `CACHI2_ARTIFACT` parameter has been removed. Prefetched dependency artifacts were never consumed by this scan task.

## Action from users

- If your pipeline passes `CACHI2_ARTIFACT` to `sast-snyk-check-oci-ta`, remove that parameter.
