# Migration from 0.3 to 0.4

- The FIND_UNICODE_CONTROL_URL parameter has been removed.

## Action from users

- If your pipeline uses the FIND_UNICODE_CONTROL_URL parameter, then it should be removed.

# Migration from 0.4 to 0.4.1

Version 0.4.1:

* Add the optional `TARGET_DIRS` parameter.

## Action from users

- No action required. The default value of "." preserves the existing behavior.
