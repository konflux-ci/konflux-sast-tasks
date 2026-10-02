# Changelog

<!-- Format guidelines: https://keepachangelog.com/en/1.1.0/#how -->

## Unreleased

<!--
When you make changes without bumping the version right away, document them here.
If that's not something you ever plan to do, consider removing this section.
-->

*Nothing yet.*

## 0.1.1

### Fixed

- Added the missing migration that removes the obsolete `CACHI2_ARTIFACT` parameter
  from user pipelines. The parameter was dropped from the task definition in an
  earlier release, but pipelines kept passing it.

## 0.1.0

### Added

- The initial version of the `sast-shell-check-oci-ta-min` task!
