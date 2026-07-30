# Migration from 0.4 to 0.5

Version 0.5:

- The unused `CACHI2_ARTIFACT` parameter has been removed. Prefetched dependency artifacts were never consumed by this scan task.

## Action from users

- If your pipeline passes `CACHI2_ARTIFACT` to `sast-unicode-check-oci-ta-min`, remove that parameter.
