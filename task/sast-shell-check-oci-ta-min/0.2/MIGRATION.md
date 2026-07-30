# Migration from 0.1 to 0.2

Version 0.2:

- The unused `CACHI2_ARTIFACT` parameter has been removed. Prefetched dependency artifacts were never consumed by this scan task.

## Action from users

- If your pipeline passes `CACHI2_ARTIFACT` to `sast-shell-check-oci-ta-min`, remove that parameter.
