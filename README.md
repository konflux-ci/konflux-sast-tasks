# Konflux SAST Tasks Catalog

## Introduction

This repository contains a collection of [Tekton](https://tekton.dev/) resources and helpers designed to support building and running SAST tasks in the [Konflux CI](https://konflux-ci.dev/docs/) pipelines. The goal is to provide a trusted set of testing tasks that can be used to ensure the quality and security of the images that are built in the Konflux CI system.

The tasks within this repository were migrated from the [Konflux build definitions repository](https://github.com/konflux-ci/build-definitions), which now holds the base build pipeline definitions and templates that reference these tasks.

## Structure

This repository is organized into several key directories, each serving a specific purpose for Tekton-related resources.

### Tasks

The `tasks` directory contains standardized [Tekton tasks](https://tekton.dev/docs/pipelines/tasks/) that are used to run different kinds of SAST tests for container builds.

#### Adding a New Task

To add a new task, create a `.yaml` file inside the `tasks/<your-task-name>/0.1/` directory. Ensure it follows the Tekton [Task specification](https://tekton.dev/docs/pipelines/tasks/), is well-documented (add `README.md` file), [well-versioned](#-versioning) and includes example usage.

Refer to the [Building Tekton tasks as bundles in Konflux](https://konflux-ci.dev/docs/end-to-end/building-tekton-tasks/) guide for details on how to onboard the new Tekton tasks to Konflux, enabling their integration into the Konflux build pipelines.

#### Versioning

We follow a **versioning strategy** to ensure updates don’t break existing workflows.

A **new version** of a task should be created **if**:

- The task’s **interface changes** (e.g., parameters, workspaces, or result names are modified).
- New functionality is introduced that **isn’t backward compatible**.
- A critical bug fix **requires an updated implementation**.

Each version should be **clearly labeled** to avoid breaking existing pipelines. A `MIGRATION.md` file needs to be supplied containing instructions for migrating to the new version of the task.

### Policies

The `policies` directory contains the [Conforma](https://conforma.dev/docs/user-guide/index.html) policies that need to be applied when building bundle images of individual tasks.

### Task generator
The `task-generator` directory contains a collection of tools used for generating various versions of tasks.

### Scripts

The `hack` directory contains the various scripts that are used during the CI runs of the build/test/release workflow for the individual Tekton tasks.

