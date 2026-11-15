#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pyyaml==6.0.2",
# ]
# ///
"""Check Task steps/sidecars for computeResources (v1) or resources (v1beta1)."""

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterator

try:
    import yaml
except ImportError:
    print("PyYAML is required. Run: uv run hack/check-compute-resources.py", file=sys.stderr)
    sys.exit(2)

EXCEPTIONS_NAME = ".compute-resources-exceptions.yaml"


@dataclass(frozen=True)
class Finding:
    path: Path
    kind: str
    name: str
    message: str


def catalog_root() -> Path:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
        return Path(out.strip())
    except (OSError, subprocess.CalledProcessError):
        return Path(__file__).resolve().parent.parent


def is_task_file(path: Path, root: Path) -> bool:
    rel = path.relative_to(root)
    match rel.parts:
        case ["task", task_dir, *_, task_file] if task_file.endswith(".yaml"):
            return task_file.removesuffix(".yaml") == task_dir
        case _:
            return False


def iter_task_files(root: Path) -> Iterator[Path]:
    task_root = root / "task"
    if not task_root.is_dir():
        return
    for path in sorted(task_root.rglob("*.yaml")):
        if is_task_file(path, root):
            yield path


def find_exceptions(root: Path) -> Path | None:
    for candidate in [root / ".github" / EXCEPTIONS_NAME, root / EXCEPTIONS_NAME]:
        if candidate.is_file():
            return candidate
    return None


def load_exceptions(path: Path | None) -> dict[str, dict[str, set[str]]]:
    if path is None:
        return {}

    data = yaml.safe_load(path.read_text())
    if data is None:
        return {}
    if not isinstance(data, dict) or not isinstance(data.get("exceptions"), list):
        raise ValueError(f"{path}: expected a mapping with an 'exceptions' list")

    result: dict[str, dict[str, set[str]]] = {}
    for entry in data["exceptions"]:
        if not isinstance(entry, dict) or "path" not in entry:
            raise ValueError(f"{path}: invalid exception entry: {entry!r}")
        rel = str(entry["path"])
        steps = entry.get("steps") or []
        sidecars = entry.get("sidecars") or []
        if not isinstance(steps, list) or not isinstance(sidecars, list):
            raise ValueError(f"{path}: steps/sidecars must be lists in {rel}")
        if not steps and not sidecars:
            raise ValueError(f"{path}: {rel} must list steps and/or sidecars")
        result[rel] = {
            "steps": {str(name) for name in steps},
            "sidecars": {str(name) for name in sidecars},
        }
    return result


def resource_field(api_version: Any) -> str:
    return "resources" if str(api_version).endswith("/v1beta1") else "computeResources"


def compute_resources(obj: dict[str, Any], field: str) -> dict[str, Any] | None:
    if field in obj:
        return obj.get(field) or {}
    return None


def merge_compute_resources(
    base: dict[str, Any] | None,
    overlay: dict[str, Any] | None,
) -> dict[str, Any] | None:
    if overlay is None:
        return base
    if base is None:
        return overlay
    return {
        "requests": {**(base.get("requests") or {}), **(overlay.get("requests") or {})},
        "limits": {**(base.get("limits") or {}), **(overlay.get("limits") or {})},
    }


def check_resources(
    path: Path,
    kind: str,
    step: dict[str, Any],
    cr: dict[str, Any] | None,
    field: str,
) -> list[Finding]:
    name = step.get("name") or f"<{kind}>"
    findings: list[Finding] = []

    if cr is None:
        other = "resources" if field == "computeResources" else "computeResources"
        if other in step:
            findings.append(Finding(path, kind, name, f"has {other} but requires {field}"))
        else:
            findings.append(Finding(path, kind, name, f"missing {field}"))
        return findings

    requests = cr.get("requests") or {}
    limits = cr.get("limits") or {}

    mem_req = requests.get("memory")
    mem_lim = limits.get("memory")
    if mem_req is None:
        findings.append(Finding(path, kind, name, "missing memory request"))
    if mem_lim is None:
        findings.append(Finding(path, kind, name, "missing memory limit"))
    if mem_req is not None and mem_lim is not None and mem_req != mem_lim:
        findings.append(
            Finding(path, kind, name, f"memory request ({mem_req}) must equal memory limit ({mem_lim})")
        )

    cpu_req = requests.get("cpu")
    cpu_lim = limits.get("cpu")
    if cpu_req is None:
        findings.append(Finding(path, kind, name, "missing cpu request"))
    if cpu_lim is not None and cpu_req is not None and cpu_lim != cpu_req:
        findings.append(
            Finding(path, kind, name, f"cpu limit ({cpu_lim}) must equal cpu request ({cpu_req})")
        )

    return findings


def check_task_file(path: Path, rel: Path) -> tuple[list[Finding], set[tuple[str, str]]]:
    data = yaml.safe_load(path.read_text())
    if not isinstance(data, dict):
        raise ValueError(f"{rel}: expected a mapping at document root")

    api_version = str(data.get("apiVersion") or "tekton.dev/v1")
    field = resource_field(api_version)
    spec = data.get("spec") or {}
    template = spec.get("stepTemplate") or {}
    template_cr = compute_resources(template, field) if isinstance(template, dict) else None

    findings: list[Finding] = []
    all_keys: set[tuple[str, str]] = set()
    for kind in ("steps", "sidecars"):
        for step in spec.get(kind) or []:
            if not isinstance(step, dict):
                continue
            name = str(step.get("name") or f"<{kind}>")
            all_keys.add((kind, name))
            cr = compute_resources(step, field)
            if kind == "steps":
                cr = merge_compute_resources(template_cr, cr)
            findings.extend(check_resources(rel, kind, step, cr, field))
    return findings, all_keys


def collect_findings(
    root: Path, exceptions: dict[str, dict[str, set[str]]]
) -> list[Finding]:
    findings: list[Finding] = []
    seen: set[str] = set()
    for path in iter_task_files(root):
        rel = path.relative_to(root)
        rel_s = rel.as_posix()
        seen.add(rel_s)
        file_findings, all_keys = check_task_file(path, rel)
        allow = exceptions.get(rel_s, {"steps": set(), "sidecars": set()})
        violated = {(f.kind, f.name) for f in file_findings}
        for f in file_findings:
            if f.name in allow.get(f.kind, set()):
                continue
            findings.append(f)
        for kind in ("steps", "sidecars"):
            for name in sorted(allow.get(kind, set())):
                if (kind, name) not in all_keys:
                    findings.append(
                        Finding(rel, kind, name, "listed in exceptions but does not exist; remove it")
                    )
                elif (kind, name) not in violated:
                    findings.append(
                        Finding(rel, kind, name, "listed in exceptions but is now compliant; remove it")
                    )
    for rel_s in exceptions:
        if rel_s not in seen:
            findings.append(
                Finding(Path(rel_s), "", "", "listed in exceptions but is not a scanned task file; remove it")
            )
    return findings


def emit(findings: list[Finding]) -> int:
    for f in findings:
        if f.kind and f.name:
            print(f"ERROR: {f.path} {f.kind} '{f.name}': {f.message}", file=sys.stderr)
        else:
            print(f"ERROR: {f.path}: {f.message}", file=sys.stderr)
    if findings:
        print(f"\n{len(findings)} computeResources violation(s) found.", file=sys.stderr)
        return 1
    print("All scanned task files satisfy computeResources rules.")
    return 0


def main() -> int:
    root = catalog_root()
    exceptions = load_exceptions(find_exceptions(root))
    return emit(collect_findings(root, exceptions))


if __name__ == "__main__":
    sys.exit(main())
